defmodule PuffinAgents.AgentWorkerTest do
  use ExUnit.Case, async: true
  
  alias PuffinAgents.AgentWorker
  alias PuffinAgents.AgentSupervisor
  
  setup do
    # Start the supervision tree for tests
    start_supervised!(PuffinAgents.AgentSupervisor)
    start_supervised!({Registry, keys: :unique, name: PuffinAgents.AgentRegistry})
    start_supervised!({Phoenix.PubSub, name: PuffinAgents.PubSub})
    
    :ok
  end
  
  describe "agent lifecycle" do
    test "spawns an agent successfully" do
      agent_id = "test_agent_#{:rand.uniform(1000)}"
      
      {:ok, pid} = AgentSupervisor.spawn_agent(
        agent_id: agent_id,
        project_path: "/tmp/test"
      )
      
      assert is_pid(pid)
      assert Process.alive?(pid)
      
      # Clean up
      AgentSupervisor.terminate_agent(agent_id)
    end
    
    test "agent can be stopped gracefully" do
      agent_id = "test_agent_#{:rand.uniform(1000)}"
      
      {:ok, pid} = AgentSupervisor.spawn_agent(
        agent_id: agent_id,
        project_path: "/tmp/test"
      )
      
      assert :ok = AgentWorker.stop(agent_id)
      refute Process.alive?(pid)
    end
    
    test "retrieves agent state" do
      agent_id = "test_agent_#{:rand.uniform(1000)}"
      
      AgentSupervisor.spawn_agent(
        agent_id: agent_id,
        project_path: "/tmp/test"
      )
      
      state = AgentWorker.get_state(agent_id)
      
      assert state.agent_id == agent_id
      assert state.status == :idle
      assert state.fitness_score == 0.0
      assert state.history == []
      
      # Clean up
      AgentSupervisor.terminate_agent(agent_id)
    end
  end
  
  describe "fitness tracking" do
    test "updates fitness score" do
      agent_id = "test_agent_#{:rand.uniform(1000)}"
      
      AgentSupervisor.spawn_agent(
        agent_id: agent_id,
        project_path: "/tmp/test"
      )
      
      AgentWorker.update_fitness(agent_id, 0.85)
      
      state = AgentWorker.get_state(agent_id)
      assert state.fitness_score == 0.85
      
      # Clean up
      AgentSupervisor.terminate_agent(agent_id)
    end
  end
  
  describe "agent registry" do
    test "agent is registered correctly" do
      agent_id = "test_agent_#{:rand.uniform(1000)}"
      
      {:ok, pid} = AgentSupervisor.spawn_agent(
        agent_id: agent_id,
        project_path: "/tmp/test"
      )
      
      assert [{^pid, _}] = Registry.lookup(PuffinAgents.AgentRegistry, agent_id)
      
      # Clean up
      AgentSupervisor.terminate_agent(agent_id)
    end
  end
end
