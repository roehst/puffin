defmodule PuffinAgents.Evolution do
  @moduledoc """
  Implements evolutionary algorithms for agent improvement.
  
  Features:
  - Fitness evaluation based on task performance
  - Agent selection and breeding
  - Mutation and crossover of agent configurations
  - Generation management and tracking
  """
  
  require Logger
  
  @type agent_genome :: %{
    agent_id: String.t(),
    generation: non_neg_integer(),
    config: map(),
    fitness: float(),
    parent_ids: [String.t()]
  }
  
  @type population :: [agent_genome()]
  
  ## Public API
  
  @doc """
  Evaluates fitness of all agents in the current population.
  
  Fitness is calculated based on:
  - Success rate on tasks
  - Response time efficiency
  - Token usage efficiency
  - Tool usage effectiveness
  """
  @spec evaluate_population() :: {:ok, [{String.t(), float()}]}
  def evaluate_population do
    agents = PuffinAgents.AgentSupervisor.list_agents()
    
    fitness_scores =
      Enum.map(agents, fn %{agent_id: agent_id, state: state} ->
        score = calculate_fitness(state)
        PuffinAgents.AgentWorker.update_fitness(agent_id, score)
        {agent_id, score}
      end)
    
    Logger.info("Evaluated population fitness: #{inspect(fitness_scores)}")
    {:ok, fitness_scores}
  end
  
  @doc """
  Selects agents for breeding based on fitness scores.
  Uses tournament selection.
  """
  @spec select_parents(population(), non_neg_integer()) :: [agent_genome()]
  def select_parents(population, count) do
    tournament_size = 3
    
    for _ <- 1..count do
      tournament_selection(population, tournament_size)
    end
  end
  
  @doc """
  Creates a new generation of agents through crossover and mutation.
  
  Options:
    - `:population_size` - Target size for new generation
    - `:mutation_rate` - Probability of mutation (0.0 to 1.0)
    - `:elite_count` - Number of best agents to keep unchanged
  """
  @spec create_next_generation(keyword()) :: {:ok, [String.t()]} | {:error, term()}
  def create_next_generation(opts) do
    population_size = Keyword.fetch!(opts, :population_size)
    mutation_rate = Keyword.get(opts, :mutation_rate, 0.1)
    elite_count = Keyword.get(opts, :elite_count, 2)
    project_path = Keyword.fetch!(opts, :project_path)
    
    # Get current population
    current_agents = PuffinAgents.AgentSupervisor.list_agents()
    population = agents_to_genomes(current_agents)
    
    # Sort by fitness
    sorted_pop = Enum.sort_by(population, & &1.fitness, :desc)
    
    # Keep elite agents
    elite = Enum.take(sorted_pop, elite_count)
    
    # Generate new agents through breeding
    offspring_count = population_size - elite_count
    parents = select_parents(sorted_pop, offspring_count * 2)
    
    offspring =
      parents
      |> Enum.chunk_every(2)
      |> Enum.take(offspring_count)
      |> Enum.map(fn [parent1, parent2] ->
        crossover(parent1, parent2, mutation_rate)
      end)
    
    # Combine elite and offspring
    new_generation = elite ++ offspring
    
    # Terminate old agents
    PuffinAgents.AgentSupervisor.terminate_all()
    
    # Spawn new generation
    new_agent_ids =
      for genome <- new_generation do
        agent_id = genome.agent_id
        
        PuffinAgents.AgentSupervisor.spawn_agent(
          agent_id: agent_id,
          project_path: project_path,
          config: genome.config
        )
        
        agent_id
      end
    
    Logger.info("Created generation #{current_generation() + 1} with #{length(new_agent_ids)} agents")
    {:ok, new_agent_ids}
  end
  
  @doc """
  Gets the current generation number.
  """
  @spec current_generation() :: non_neg_integer()
  def current_generation do
    agents = PuffinAgents.AgentSupervisor.list_agents()
    
    agents
    |> Enum.map(fn %{agent_id: id} ->
      extract_generation_from_id(id)
    end)
    |> Enum.max(fn -> 0 end)
  end
  
  ## Private Functions
  
  defp calculate_fitness(state) do
    stats = state.stats
    
    # Success rate (higher is better)
    success_rate = Map.get(stats, :success_rate, 0.0)
    
    # Token efficiency (lower tokens per task is better)
    token_efficiency =
      if stats.prompts_processed > 0 do
        1.0 / (stats.total_tokens / stats.prompts_processed / 1000.0 + 1.0)
      else
        0.0
      end
    
    # Response time (faster is better)
    time_efficiency =
      if stats.avg_response_time > 0 do
        1.0 / (stats.avg_response_time / 60.0 + 1.0)
      else
        0.5
      end
    
    # Tool usage diversity (more tools used indicates versatility)
    tool_diversity =
      case Map.get(stats, :tool_usage) do
        tools when is_map(tools) -> map_size(tools) / 10.0
        _ -> 0.0
      end
    
    # Weighted combination
    fitness =
      success_rate * 0.4 +
      token_efficiency * 0.3 +
      time_efficiency * 0.2 +
      tool_diversity * 0.1
    
    Float.round(fitness, 4)
  end
  
  defp agents_to_genomes(agents) do
    Enum.map(agents, fn %{agent_id: agent_id, state: state} ->
      generation = extract_generation_from_id(agent_id)
      
      %{
        agent_id: agent_id,
        generation: generation,
        config: %{},  # Would be populated from actual agent config
        fitness: state.fitness_score,
        parent_ids: []
      }
    end)
  end
  
  defp extract_generation_from_id(agent_id) do
    # Extract generation number from agent_id format: "agent_XXX_genN"
    case Regex.run(~r/gen(\d+)/, agent_id) do
      [_, gen_str] -> String.to_integer(gen_str)
      _ -> 0
    end
  end
  
  defp tournament_selection(population, tournament_size) do
    population
    |> Enum.take_random(tournament_size)
    |> Enum.max_by(& &1.fitness)
  end
  
  defp crossover(parent1, parent2, mutation_rate) do
    new_gen = parent1.generation + 1
    new_id = "agent_#{:erlang.unique_integer([:positive])}_gen#{new_gen}"
    
    # Simple config crossover: take random elements from each parent
    new_config =
      merge_configs(parent1.config, parent2.config)
      |> maybe_mutate(mutation_rate)
    
    %{
      agent_id: new_id,
      generation: new_gen,
      config: new_config,
      fitness: 0.0,
      parent_ids: [parent1.agent_id, parent2.agent_id]
    }
  end
  
  defp merge_configs(config1, config2) do
    # Simple merge strategy: randomly pick values from either parent
    all_keys = Map.keys(config1) ++ Map.keys(config2) |> Enum.uniq()
    
    Enum.reduce(all_keys, %{}, fn key, acc ->
      value =
        if :rand.uniform() > 0.5 do
          Map.get(config1, key)
        else
          Map.get(config2, key)
        end
      
      if value, do: Map.put(acc, key, value), else: acc
    end)
  end
  
  defp maybe_mutate(config, mutation_rate) do
    if :rand.uniform() < mutation_rate do
      mutate_config(config)
    else
      config
    end
  end
  
  defp mutate_config(config) do
    # Simple mutation: modify a random configuration value
    keys = Map.keys(config)
    
    if length(keys) > 0 do
      key_to_mutate = Enum.random(keys)
      
      mutated_value =
        case Map.get(config, key_to_mutate) do
          val when is_float(val) -> val * (:rand.uniform() * 0.4 + 0.8)
          val when is_integer(val) -> val + Enum.random(-2..2)
          val when is_boolean(val) -> not val
          val -> val
        end
      
      Map.put(config, key_to_mutate, mutated_value)
    else
      config
    end
  end
end
