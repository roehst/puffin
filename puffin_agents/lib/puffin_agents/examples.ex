defmodule PuffinAgents.Examples do
  @moduledoc """
  Example usage scenarios for Puffin Agents.
  
  These examples demonstrate common use cases for the multi-agent system.
  """
  
  require Logger
  
  @doc """
  Example 1: Single agent with a simple task.
  """
  def single_agent_example do
    Logger.info("=== Single Agent Example ===")
    
    # Spawn a single agent
    {:ok, _pid} = PuffinAgents.AgentSupervisor.spawn_agent(
      agent_id: "solo_agent",
      project_path: "/tmp/test_project"
    )
    
    # Submit a prompt
    PuffinAgents.AgentWorker.submit_prompt(
      "solo_agent",
      "Create a simple Hello World web server in Node.js with Express"
    )
    
    # Wait a bit for processing
    :timer.sleep(5000)
    
    # Check the state
    state = PuffinAgents.AgentWorker.get_state("solo_agent")
    Logger.info("Agent state: #{inspect(state.status)}")
    Logger.info("History entries: #{length(state.history)}")
    
    # Clean up
    PuffinAgents.AgentWorker.stop("solo_agent")
  end
  
  @doc """
  Example 2: Multiple agents working in parallel.
  """
  def parallel_agents_example do
    Logger.info("=== Parallel Agents Example ===")
    
    tasks = [
      "Create a user authentication endpoint",
      "Create a database schema for users",
      "Create a frontend login form",
      "Write unit tests for authentication"
    ]
    
    # Spawn multiple agents
    agent_ids = 
      Enum.map(1..4, fn i ->
        agent_id = "agent_#{i}"
        {:ok, _} = PuffinAgents.AgentSupervisor.spawn_agent(
          agent_id: agent_id,
          project_path: "/tmp/parallel_project_#{i}"
        )
        agent_id
      end)
    
    # Assign tasks to agents
    Enum.zip(agent_ids, tasks)
    |> Enum.each(fn {agent_id, task} ->
      Logger.info("Assigning to #{agent_id}: #{task}")
      PuffinAgents.AgentWorker.submit_prompt(agent_id, task)
    end)
    
    # Wait for completion
    :timer.sleep(30000)
    
    # Check results
    results = 
      Enum.map(agent_ids, fn agent_id ->
        state = PuffinAgents.AgentWorker.get_state(agent_id)
        {agent_id, state.status, length(state.history)}
      end)
    
    Logger.info("Results: #{inspect(results)}")
    
    # Clean up
    Enum.each(agent_ids, &PuffinAgents.AgentWorker.stop/1)
  end
  
  @doc """
  Example 3: Evolutionary algorithm with population.
  """
  def evolution_example do
    Logger.info("=== Evolution Example ===")
    
    project_path = "/tmp/evolution_project"
    population_size = 10
    generations = 3
    
    # Initial population
    {:ok, agent_ids} = PuffinAgents.AgentSupervisor.spawn_population(
      population_size: population_size,
      project_path: project_path
    )
    
    Logger.info("Spawned initial population: #{inspect(agent_ids)}")
    
    # Run for multiple generations
    for generation <- 1..generations do
      Logger.info("=== Generation #{generation} ===")
      
      # Assign same task to all agents
      task = "Optimize this bubble sort implementation for better performance"
      Enum.each(agent_ids, fn agent_id ->
        PuffinAgents.AgentWorker.submit_prompt(agent_id, task)
      end)
      
      # Wait for completion
      :timer.sleep(20000)
      
      # Evaluate fitness
      {:ok, fitness_scores} = PuffinAgents.Evolution.evaluate_population()
      Logger.info("Fitness scores: #{inspect(fitness_scores)}")
      
      # Create next generation (if not last)
      if generation < generations do
        {:ok, new_agent_ids} = PuffinAgents.Evolution.create_next_generation(
          population_size: population_size,
          mutation_rate: 0.15,
          elite_count: 2,
          project_path: project_path
        )
        
        Logger.info("New generation spawned: #{inspect(new_agent_ids)}")
      end
    end
    
    # Final evaluation
    {:ok, final_scores} = PuffinAgents.Evolution.evaluate_population()
    best_agent = Enum.max_by(final_scores, fn {_, score} -> score end)
    Logger.info("Best agent after #{generations} generations: #{inspect(best_agent)}")
    
    # Clean up
    PuffinAgents.AgentSupervisor.terminate_all()
  end
  
  @doc """
  Example 4: Agent with event subscription.
  """
  def event_subscription_example do
    Logger.info("=== Event Subscription Example ===")
    
    agent_id = "monitored_agent"
    
    # Subscribe to agent events
    Phoenix.PubSub.subscribe(PuffinAgents.PubSub, "agent:#{agent_id}")
    
    # Spawn agent
    {:ok, _pid} = PuffinAgents.AgentSupervisor.spawn_agent(
      agent_id: agent_id,
      project_path: "/tmp/monitored_project"
    )
    
    # Submit task
    PuffinAgents.AgentWorker.submit_prompt(
      agent_id,
      "Create a factorial function with error handling"
    )
    
    # Listen for events
    listen_for_events(30000)
    
    # Clean up
    Phoenix.PubSub.unsubscribe(PuffinAgents.PubSub, "agent:#{agent_id}")
    PuffinAgents.AgentWorker.stop(agent_id)
  end
  
  @doc """
  Example 5: Fault tolerance demonstration.
  """
  def fault_tolerance_example do
    Logger.info("=== Fault Tolerance Example ===")
    
    agent_id = "resilient_agent"
    
    # Spawn agent
    {:ok, pid} = PuffinAgents.AgentSupervisor.spawn_agent(
      agent_id: agent_id,
      project_path: "/tmp/resilient_project"
    )
    
    Logger.info("Agent spawned with PID: #{inspect(pid)}")
    
    # Submit a task
    PuffinAgents.AgentWorker.submit_prompt(
      agent_id,
      "Create a complex data structure"
    )
    
    # Simulate crash after a moment
    :timer.sleep(2000)
    Logger.info("Simulating agent crash...")
    Process.exit(pid, :kill)
    
    # Wait for supervisor to restart
    :timer.sleep(1000)
    
    # Check if agent was restarted
    case Registry.lookup(PuffinAgents.AgentRegistry, agent_id) do
      [{new_pid, _}] ->
        Logger.info("Agent auto-restarted with new PID: #{inspect(new_pid)}")
        Logger.info("Fault tolerance working correctly!")
      
      [] ->
        Logger.warn("Agent not restarted (might be expected based on restart strategy)")
    end
    
    # Clean up
    PuffinAgents.AgentSupervisor.terminate_agent(agent_id)
  end
  
  @doc """
  Example 6: Performance comparison.
  """
  def performance_benchmark do
    Logger.info("=== Performance Benchmark ===")
    
    agent_counts = [1, 5, 10, 20]
    task = "Write a simple function that adds two numbers"
    
    Enum.each(agent_counts, fn count ->
      Logger.info("Benchmarking with #{count} agents...")
      
      # Spawn agents
      {spawn_time, agent_ids} = :timer.tc(fn ->
        for i <- 1..count do
          agent_id = "bench_agent_#{i}"
          {:ok, _} = PuffinAgents.AgentSupervisor.spawn_agent(
            agent_id: agent_id,
            project_path: "/tmp/bench_project_#{i}"
          )
          agent_id
        end
      end)
      
      Logger.info("  Spawn time: #{spawn_time / 1000}ms (#{spawn_time / count / 1000}ms per agent)")
      
      # Submit tasks
      {submit_time, _} = :timer.tc(fn ->
        Enum.each(agent_ids, fn agent_id ->
          PuffinAgents.AgentWorker.submit_prompt(agent_id, task)
        end)
      end)
      
      Logger.info("  Submit time: #{submit_time / 1000}ms")
      
      # Clean up
      Enum.each(agent_ids, &PuffinAgents.AgentWorker.stop/1)
      :timer.sleep(100)
    end)
  end
  
  ## Helper Functions
  
  defp listen_for_events(timeout) do
    receive do
      {:assistant_message, data} ->
        Logger.info("Assistant message: #{inspect(data)}")
        listen_for_events(timeout)
      
      {:completion, data} ->
        Logger.info("Completion: #{inspect(data)}")
      
      other ->
        Logger.info("Other event: #{inspect(other)}")
        listen_for_events(timeout)
    after
      timeout ->
        Logger.info("Event listening timed out")
    end
  end
  
  @doc """
  Run all examples in sequence.
  """
  def run_all do
    examples = [
      {"Single Agent", &single_agent_example/0},
      {"Parallel Agents", &parallel_agents_example/0},
      {"Evolution", &evolution_example/0},
      {"Event Subscription", &event_subscription_example/0},
      {"Fault Tolerance", &fault_tolerance_example/0},
      {"Performance Benchmark", &performance_benchmark/0}
    ]
    
    Enum.each(examples, fn {name, example_fn} ->
      Logger.info("\n" <> String.duplicate("=", 60))
      Logger.info("Running: #{name}")
      Logger.info(String.duplicate("=", 60) <> "\n")
      
      try do
        example_fn.()
        Logger.info("✓ #{name} completed successfully")
      rescue
        error ->
          Logger.error("✗ #{name} failed: #{inspect(error)}")
      end
      
      # Pause between examples
      :timer.sleep(2000)
    end)
    
    Logger.info("\n" <> String.duplicate("=", 60))
    Logger.info("All examples completed!")
    Logger.info(String.duplicate("=", 60))
  end
end
