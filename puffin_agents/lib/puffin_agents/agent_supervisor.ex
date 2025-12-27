defmodule PuffinAgents.AgentSupervisor do
  @moduledoc """
  DynamicSupervisor that manages multiple Claude agent workers.
  
  Provides:
  - Dynamic agent spawning and termination
  - Fault tolerance and automatic restarts
  - Agent lifecycle management
  - Population management for evolutionary algorithms
  """
  
  use DynamicSupervisor
  require Logger
  
  @type agent_config :: %{
    agent_id: String.t(),
    project_path: String.t(),
    config: map()
  }
  
  ## Client API
  
  @doc """
  Starts the agent supervisor.
  """
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @doc """
  Spawns a new agent worker.
  
  Options:
    - `:agent_id` - Unique identifier for the agent
    - `:project_path` - Path to the project directory
    - `:config` - Additional configuration map
  """
  @spec spawn_agent(keyword()) :: DynamicSupervisor.on_start_child()
  def spawn_agent(opts) do
    agent_id = Keyword.fetch!(opts, :agent_id)
    
    child_spec = %{
      id: agent_id,
      start: {PuffinAgents.AgentWorker, :start_link, [opts]},
      restart: :transient
    }
    
    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:ok, pid} = result ->
        Logger.info("Spawned agent: #{agent_id} (#{inspect(pid)})")
        result
      
      {:error, {:already_started, pid}} ->
        Logger.warn("Agent already exists: #{agent_id} (#{inspect(pid)})")
        {:ok, pid}
      
      error ->
        Logger.error("Failed to spawn agent #{agent_id}: #{inspect(error)}")
        error
    end
  end
  
  @doc """
  Terminates an agent worker.
  """
  @spec terminate_agent(String.t()) :: :ok | {:error, :not_found}
  def terminate_agent(agent_id) do
    case Registry.lookup(PuffinAgents.AgentRegistry, agent_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
        Logger.info("Terminated agent: #{agent_id}")
        :ok
      
      [] ->
        Logger.warn("Agent not found: #{agent_id}")
        {:error, :not_found}
    end
  end
  
  @doc """
  Lists all running agents.
  """
  @spec list_agents() :: [%{agent_id: String.t(), pid: pid(), state: map()}]
  def list_agents do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      case Registry.keys(PuffinAgents.AgentRegistry, pid) do
        [agent_id] ->
          state = PuffinAgents.AgentWorker.get_state(agent_id)
          %{agent_id: agent_id, pid: pid, state: state}
        
        [] ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
  
  @doc """
  Counts the number of running agents.
  """
  @spec count_agents() :: non_neg_integer()
  def count_agents do
    DynamicSupervisor.count_children(__MODULE__).active
  end
  
  @doc """
  Spawns a population of agents for evolutionary algorithms.
  
  Options:
    - `:population_size` - Number of agents to spawn
    - `:project_path` - Base project path
    - `:agent_configs` - List of configuration maps for each agent
  """
  @spec spawn_population(keyword()) :: {:ok, [String.t()]} | {:error, term()}
  def spawn_population(opts) do
    population_size = Keyword.fetch!(opts, :population_size)
    project_path = Keyword.fetch!(opts, :project_path)
    agent_configs = Keyword.get(opts, :agent_configs, [])
    
    agent_ids =
      for i <- 1..population_size do
        agent_id = "agent_#{:erlang.unique_integer([:positive])}_gen0"
        config = Enum.at(agent_configs, i - 1, %{})
        
        spawn_agent(
          agent_id: agent_id,
          project_path: project_path,
          config: config
        )
        
        agent_id
      end
    
    Logger.info("Spawned population of #{population_size} agents")
    {:ok, agent_ids}
  end
  
  @doc """
  Terminates all agents.
  """
  @spec terminate_all() :: :ok
  def terminate_all do
    list_agents()
    |> Enum.each(fn %{agent_id: agent_id} ->
      terminate_agent(agent_id)
    end)
    
    Logger.info("Terminated all agents")
    :ok
  end
  
  ## Server Callbacks
  
  @impl true
  def init(_init_arg) do
    Logger.info("Starting agent supervisor")
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 10, max_seconds: 5)
  end
end
