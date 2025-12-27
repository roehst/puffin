# Puffin Agents - Elixir Multi-Agent System

An Elixir-based multi-agent system for running Claude Code agents with supervision and evolutionary capabilities.

## Overview

This project translates the original Node.js/Electron-based Puffin into an Elixir OTP application that can:

- **Run multiple Claude agents concurrently** on separate VMs or processes
- **Supervise agents** using Elixir's battle-tested OTP supervision trees
- **Evolve agents** using genetic algorithms to improve performance
- **Scale horizontally** across multiple nodes in a distributed system
- **Provide fault tolerance** with automatic agent restarts
- **Track fitness** and performance metrics for each agent

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    PuffinAgents.Application                     │
│                    (OTP Application)                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────┐      ┌──────────────────────────────┐   │
│  │ AgentRegistry     │      │ Phoenix.PubSub               │   │
│  │ (Agent Discovery) │      │ (Event Broadcasting)         │   │
│  └───────────────────┘      └──────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           PuffinAgents.AgentSupervisor                   │   │
│  │           (Dynamic Supervisor)                           │   │
│  │                                                          │   │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │   │ AgentWorker  │  │ AgentWorker  │  │ AgentWorker  │  │   │
│  │   │ (Agent #1)   │  │ (Agent #2)   │  │ (Agent #N)   │   │   │
│  │   │              │  │              │  │              │  │   │
│  │   │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │  │   │
│  │   │ │ Port to  │ │  │ │ Port to  │ │  │ │ Port to  │ │  │   │
│  │   │ │ Claude   │ │  │ │ Claude   │ │  │ │ Claude   │ │  │   │
│  │   │ │ CLI      │ │  │ │ CLI      │ │  │ │ CLI      │ │  │   │
│  │   │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │  │   │
│  │   └──────────────┘  └──────────────┘  └──────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           PuffinAgents.Evolution                         │   │
│  │           (Genetic Algorithm)                            │   │
│  │                                                          │   │
│  │  - Fitness Evaluation                                    │   │
│  │  - Agent Selection                                       │   │
│  │  - Crossover & Mutation                                  │   │
│  │  - Generation Management                                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. AgentWorker (GenServer)

Each `AgentWorker` is a GenServer that:
- Spawns and manages a Claude CLI subprocess via Elixir Port
- Maintains conversation state and history
- Handles JSON streaming responses from Claude
- Tracks tool usage and performance metrics
- Supports fitness evaluation for evolutionary algorithms

### 2. AgentSupervisor (DynamicSupervisor)

The `AgentSupervisor` provides:
- Dynamic spawning and termination of agents
- Fault tolerance with automatic restarts
- Agent lifecycle management
- Population management for evolutionary runs

### 3. Evolution Module

Implements genetic algorithms:
- **Fitness Evaluation**: Based on task success, token efficiency, response time
- **Selection**: Tournament selection for breeding
- **Crossover**: Combining configurations from parent agents
- **Mutation**: Random variations in agent parameters
- **Generation Management**: Creating and tracking agent lineages

## Installation

### Prerequisites

- Erlang/OTP 25+
- Elixir 1.14+
- Claude CLI installed and authenticated
- Node.js 18+ (optional, for the original Puffin frontend)

### Setup

```bash
# Clone the repository
cd puffin_agents

# Install dependencies
mix deps.get

# Compile
mix compile
```

## Usage

### Starting the Application

```elixir
# Start in IEx
iex -S mix

# Spawn a single agent
{:ok, _pid} = PuffinAgents.AgentSupervisor.spawn_agent(
  agent_id: "agent_001",
  project_path: "/path/to/your/project"
)

# Submit a prompt to the agent
PuffinAgents.AgentWorker.submit_prompt(
  "agent_001",
  "Create a REST API endpoint for user authentication"
)

# Check agent state
state = PuffinAgents.AgentWorker.get_state("agent_001")
IO.inspect(state)
```

### Running a Population of Agents

```elixir
# Spawn a population of agents
{:ok, agent_ids} = PuffinAgents.AgentSupervisor.spawn_population(
  population_size: 10,
  project_path: "/path/to/your/project"
)

# List all running agents
agents = PuffinAgents.AgentSupervisor.list_agents()

# Evaluate fitness of all agents
{:ok, fitness_scores} = PuffinAgents.Evolution.evaluate_population()
```

### Evolutionary Algorithm

```elixir
# Create a new generation through evolution
{:ok, new_agent_ids} = PuffinAgents.Evolution.create_next_generation(
  population_size: 10,
  mutation_rate: 0.1,
  elite_count: 2,
  project_path: "/path/to/your/project"
)

# Check current generation
generation = PuffinAgents.Evolution.current_generation()
```

## Configuration

Agents can be configured with various parameters:

```elixir
config = %{
  max_turns: 40,
  temperature: 0.7,
  thinking_budget: 5000,
  # Additional Claude CLI parameters
}

PuffinAgents.AgentSupervisor.spawn_agent(
  agent_id: "agent_custom",
  project_path: "/path/to/project",
  config: config
)
```

## Distributed Deployment

Puffin Agents can be deployed across multiple Erlang nodes:

```elixir
# Start first node
iex --sname node1@localhost -S mix

# Start second node
iex --sname node2@localhost -S mix

# Connect nodes
Node.connect(:"node2@localhost")

# Spawn agents distributed across nodes
# (Configure with :rpc or distributed task supervisors)
```

## Integration with Original Puffin

The Elixir backend can be integrated with the original Electron frontend:

1. **HTTP API**: Add Phoenix REST endpoints
2. **WebSocket**: Real-time updates via Phoenix Channels
3. **State Sync**: Persist state to shared storage (PostgreSQL, Mnesia)

Example integration architecture:

```
┌────────────────────┐
│  Electron Frontend │
│  (Original Puffin) │
└─────────┬──────────┘
          │ HTTP/WebSocket
          ▼
┌────────────────────┐
│  Phoenix API       │
│  (New Elixir API)  │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  PuffinAgents      │
│  (Agent System)    │
└────────────────────┘
```

## Evolution Strategies

### Fitness Function

Agents are evaluated on multiple criteria:
- **Success Rate**: Percentage of tasks completed successfully
- **Token Efficiency**: Lower token usage per task
- **Response Time**: Faster completion
- **Tool Diversity**: Ability to use various tools effectively

### Selection Methods

- **Tournament Selection**: Pick best agent from random subset
- **Elitism**: Keep top performers unchanged
- **Roulette Selection**: Probability proportional to fitness (future)

### Genetic Operators

- **Crossover**: Merge configurations from two parent agents
- **Mutation**: Random parameter adjustments
- **Cloning**: Keep successful agents for next generation

## Testing

```bash
# Run tests
mix test

# Run with coverage
mix test --cover

# Run specific test
mix test test/puffin_agents/agent_worker_test.exs
```

## Monitoring and Observability

### Built-in Metrics

Each agent tracks:
- Number of prompts processed
- Total tokens used
- Success rate
- Average response time
- Tool usage distribution

### Observability Integration

Can be integrated with:
- **Telemetry**: For metrics collection
- **Phoenix LiveDashboard**: Real-time monitoring
- **AppSignal/New Relic**: Production monitoring

## Deployment

### Docker

```dockerfile
FROM elixir:1.14-alpine

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY . .
RUN mix compile

CMD ["mix", "run", "--no-halt"]
```

### Kubernetes

Deploy as StatefulSet for persistent agent identities:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: puffin-agents
spec:
  serviceName: puffin-agents
  replicas: 3
  selector:
    matchLabels:
      app: puffin-agents
  template:
    spec:
      containers:
      - name: puffin-agents
        image: puffin-agents:latest
        env:
        - name: RELEASE_COOKIE
          value: "secret-cookie"
```

## Performance Considerations

- **Concurrency**: Each agent runs in its own process
- **Fault Isolation**: Agent crashes don't affect others
- **Resource Limits**: Use `:erlang.system_monitor/2` to track memory
- **Port Management**: Claude CLI processes managed via Ports

## Future Enhancements

- [ ] Phoenix LiveView UI for real-time monitoring
- [ ] Multi-objective fitness optimization (Pareto frontier)
- [ ] Agent specialization (UI experts, backend experts)
- [ ] Distributed consensus for agent coordination
- [ ] Replay buffer for experience-based learning
- [ ] Integration with reinforcement learning frameworks
- [ ] Cross-agent knowledge sharing
- [ ] Automated hyperparameter tuning

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) in the main repository.

## License

MIT - Same as the main Puffin project

## Migration from Node.js Puffin

For existing Puffin users, see [MIGRATION.md](MIGRATION.md) for guidance on transitioning to the Elixir version.
