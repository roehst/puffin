defmodule PuffinAgents.AgentWorker do
  @moduledoc """
  GenServer that manages a single Claude agent instance.
  
  Each AgentWorker:
  - Spawns and manages a Claude CLI subprocess via Port
  - Maintains conversation state and history
  - Handles JSON streaming responses
  - Tracks tool usage and file operations
  - Supports evolutionary fitness evaluation
  """
  
  use GenServer
  require Logger
  
  @type agent_id :: String.t()
  @type state :: %{
    agent_id: agent_id(),
    port: port() | nil,
    buffer: String.t(),
    session_id: String.t() | nil,
    history: list(),
    status: :idle | :processing | :error,
    fitness_score: float(),
    project_path: String.t(),
    stats: map()
  }
  
  ## Client API
  
  @doc """
  Starts an agent worker.
  
  Options:
    - `:agent_id` - Unique identifier for this agent
    - `:project_path` - Path to the project directory
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    agent_id = Keyword.fetch!(opts, :agent_id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(agent_id))
  end
  
  @doc """
  Submits a prompt to the agent.
  """
  @spec submit_prompt(agent_id(), String.t(), keyword()) :: :ok
  def submit_prompt(agent_id, prompt, opts \\ []) do
    GenServer.cast(via_tuple(agent_id), {:submit_prompt, prompt, opts})
  end
  
  @doc """
  Gets the current state of the agent.
  """
  @spec get_state(agent_id()) :: state()
  def get_state(agent_id) do
    GenServer.call(via_tuple(agent_id), :get_state)
  end
  
  @doc """
  Updates the fitness score of the agent.
  """
  @spec update_fitness(agent_id(), float()) :: :ok
  def update_fitness(agent_id, score) do
    GenServer.cast(via_tuple(agent_id), {:update_fitness, score})
  end
  
  @doc """
  Stops the agent gracefully.
  """
  @spec stop(agent_id()) :: :ok
  def stop(agent_id) do
    GenServer.stop(via_tuple(agent_id))
  end
  
  ## Server Callbacks
  
  @impl true
  def init(opts) do
    agent_id = Keyword.fetch!(opts, :agent_id)
    project_path = Keyword.get(opts, :project_path, File.cwd!())
    
    Logger.info("Starting agent worker: #{agent_id}")
    
    state = %{
      agent_id: agent_id,
      port: nil,
      buffer: "",
      session_id: nil,
      history: [],
      status: :idle,
      fitness_score: 0.0,
      project_path: project_path,
      stats: %{
        prompts_processed: 0,
        total_tokens: 0,
        success_rate: 0.0,
        avg_response_time: 0.0
      }
    }
    
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:submit_prompt, prompt, opts}, state) do
    Logger.info("Agent #{state.agent_id} processing prompt")
    
    new_state = 
      state
      |> Map.put(:status, :processing)
      |> spawn_claude_process(prompt, opts)
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_cast({:update_fitness, score}, state) do
    new_state = Map.put(state, :fitness_score, score)
    Logger.info("Agent #{state.agent_id} fitness updated: #{score}")
    {:noreply, new_state}
  end
  
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  
  @impl true
  def handle_info({port, {:data, data}}, %{port: port} = state) do
    # Handle streaming JSON data from Claude CLI
    new_buffer = state.buffer <> data
    {parsed_messages, remaining_buffer} = parse_json_stream(new_buffer)
    
    new_state =
      parsed_messages
      |> Enum.reduce(state, fn msg, acc_state ->
        process_claude_message(msg, acc_state)
      end)
      |> Map.put(:buffer, remaining_buffer)
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.info("Agent #{state.agent_id} Claude process exited with status: #{status}")
    
    new_state =
      state
      |> Map.put(:port, nil)
      |> Map.put(:status, if(status == 0, do: :idle, else: :error))
      |> update_stats()
    
    # Notify subscribers about completion
    notify_completion(state.agent_id, status)
    
    {:noreply, new_state}
  end
  
  ## Private Functions
  
  defp via_tuple(agent_id) do
    {:via, Registry, {PuffinAgents.AgentRegistry, agent_id}}
  end
  
  defp spawn_claude_process(state, prompt, opts) do
    resume_session = Keyword.get(opts, :resume_session, state.session_id)
    max_turns = Keyword.get(opts, :max_turns, 40)
    
    args = [
      "--print",
      "--output-format", "stream-json",
      "--max-turns", to_string(max_turns),
      "--prompt", prompt
    ]
    
    args = if resume_session do
      ["--resume", resume_session | args]
    else
      args
    end
    
    port = Port.open(
      {:spawn_executable, find_claude_binary()},
      [
        :binary,
        :exit_status,
        :use_stdio,
        {:cd, state.project_path},
        {:args, args}
      ]
    )
    
    Map.put(state, :port, port)
  end
  
  defp find_claude_binary do
    System.find_executable("claude") || raise "Claude CLI not found in PATH"
  end
  
  defp parse_json_stream(buffer) do
    # Split buffer by newlines and try to parse each line as JSON
    lines = String.split(buffer, "\n")
    {complete_lines, incomplete} = Enum.split(lines, -1)
    
    messages =
      complete_lines
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.flat_map(fn line ->
        case Jason.decode(line) do
          {:ok, json} -> [json]
          {:error, _} -> []
        end
      end)
    
    remaining_buffer = List.first(incomplete) || ""
    {messages, remaining_buffer}
  end
  
  defp process_claude_message(%{"type" => "assistant"} = msg, state) do
    # Handle assistant messages (Claude's responses and tool use)
    content = Map.get(msg, "content", "")
    tool_uses = Map.get(msg, "tool_uses", [])
    
    state
    |> add_to_history(msg)
    |> track_tool_usage(tool_uses)
    |> notify_subscribers(:assistant_message, %{content: content, tool_uses: tool_uses})
  end
  
  defp process_claude_message(%{"type" => "user"} = msg, state) do
    # Handle user messages (tool results)
    add_to_history(state, msg)
  end
  
  defp process_claude_message(%{"type" => "result"} = msg, state) do
    # Handle completion result with metadata
    session_id = Map.get(msg, "session_id")
    cost = Map.get(msg, "cost", 0.0)
    turns = Map.get(msg, "turns", 0)
    
    state
    |> Map.put(:session_id, session_id)
    |> add_to_history(msg)
    |> update_token_stats(cost, turns)
  end
  
  defp process_claude_message(_msg, state), do: state
  
  defp add_to_history(state, message) do
    Map.update!(state, :history, &[message | &1])
  end
  
  defp track_tool_usage(state, tool_uses) when is_list(tool_uses) do
    # Track which tools are being used for evolutionary analysis
    tool_names = Enum.map(tool_uses, & &1["name"])
    
    state
    |> Map.update!(:stats, fn stats ->
      Map.update(stats, :tool_usage, %{}, fn usage ->
        Enum.reduce(tool_names, usage, fn tool, acc ->
          Map.update(acc, tool, 1, &(&1 + 1))
        end)
      end)
    end)
  end
  
  defp track_tool_usage(state, _), do: state
  
  defp update_token_stats(state, cost, turns) do
    # Estimate tokens from cost (rough approximation)
    estimated_tokens = trunc(cost * 100_000)
    
    Map.update!(state, :stats, fn stats ->
      stats
      |> Map.update(:total_tokens, estimated_tokens, &(&1 + estimated_tokens))
      |> Map.put(:last_turns, turns)
    end)
  end
  
  defp update_stats(state) do
    stats = state.stats
    prompts = stats.prompts_processed + 1
    
    Map.update!(state, :stats, fn stats ->
      Map.put(stats, :prompts_processed, prompts)
    end)
  end
  
  defp notify_subscribers(state, event, data) do
    Phoenix.PubSub.broadcast(
      PuffinAgents.PubSub,
      "agent:#{state.agent_id}",
      {event, Map.merge(data, %{agent_id: state.agent_id})}
    )
    
    state
  end
  
  defp notify_completion(agent_id, status) do
    Phoenix.PubSub.broadcast(
      PuffinAgents.PubSub,
      "agent:#{agent_id}",
      {:completion, %{agent_id: agent_id, status: status}}
    )
  end
end
