# Migration Guide: Node.js Puffin → Elixir Puffin Agents

This guide helps you transition from the original Electron-based Puffin to the Elixir-supervised multi-agent system.

## Overview of Changes

| Aspect | Node.js Puffin | Elixir Puffin Agents |
|--------|----------------|----------------------|
| **Runtime** | Node.js + Electron | Erlang/OTP + Elixir |
| **Architecture** | Single process, single agent | Multi-process, many agents |
| **State Management** | SAM Pattern in JavaScript | OTP GenServer/Agent |
| **UI** | Electron renderer | Can use Phoenix LiveView or keep Electron |
| **Supervision** | Process manager (optional) | Built-in OTP supervision trees |
| **Scaling** | Vertical (single machine) | Horizontal (distributed nodes) |
| **Fault Tolerance** | Manual restart | Automatic supervision |
| **Evolution** | Not supported | Genetic algorithms built-in |

## Key Conceptual Mappings

### 1. AgentWorker ≈ claude-service.js

**Before (Node.js):**
```javascript
// src/main/claude-service.js
class ClaudeService {
  constructor() {
    this.currentProcess = null;
    this.sessionId = null;
  }
  
  spawn(prompt, options) {
    const args = ['--print', '--output-format', 'stream-json', ...];
    this.currentProcess = spawn('claude', args);
    // Handle streaming...
  }
}
```

**After (Elixir):**
```elixir
# lib/puffin_agents/agent_worker.ex
defmodule PuffinAgents.AgentWorker do
  use GenServer
  
  def spawn_claude_process(state, prompt, opts) do
    port = Port.open({:spawn_executable, "claude"}, [
      :binary, :exit_status, {:args, args}
    ])
    %{state | port: port}
  end
end
```

### 2. PuffinState ≈ Persistent State Management

**Before (Node.js):**
```javascript
// src/main/puffin-state.js
class PuffinState {
  async open(projectPath) {
    const puffinDir = path.join(projectPath, '.puffin');
    this.state = await fs.readJSON(path.join(puffinDir, 'config.json'));
  }
}
```

**After (Elixir):**
```elixir
# Can use GenServer, ETS, Mnesia, or PostgreSQL
defmodule PuffinAgents.StateStore do
  use GenServer
  
  def init(_) do
    :ets.new(:agent_state, [:named_table, :public])
    {:ok, %{}}
  end
  
  def save_state(agent_id, state) do
    :ets.insert(:agent_state, {agent_id, state})
  end
end
```

### 3. IPC Handlers ≈ Phoenix Controllers/Channels

**Before (Node.js):**
```javascript
// src/main/ipc-handlers.js
ipcMain.handle('claude:submit', async (event, {prompt, branchId}) => {
  const result = await claudeService.submit(prompt);
  return result;
});
```

**After (Elixir - Phoenix):**
```elixir
# lib/puffin_agents_web/controllers/agent_controller.ex
defmodule PuffinAgentsWeb.AgentController do
  use PuffinAgentsWeb, :controller
  
  def submit_prompt(conn, %{"agent_id" => id, "prompt" => prompt}) do
    PuffinAgents.AgentWorker.submit_prompt(id, prompt)
    json(conn, %{status: "submitted"})
  end
end
```

## Migration Steps

### Phase 1: Setup Elixir Environment

1. **Install Elixir and dependencies**
   ```bash
   # On Ubuntu/Debian
   sudo apt-get install erlang elixir
   
   # On macOS
   brew install elixir
   ```

2. **Create Elixir project**
   ```bash
   cd puffin
   mix new puffin_agents --sup
   cd puffin_agents
   ```

3. **Add dependencies to mix.exs**
   ```elixir
   defp deps do
     [
       {:phoenix_pubsub, "~> 2.1"},
       {:jason, "~> 1.4"},
       {:phoenix, "~> 1.7"},  # If adding web interface
       {:phoenix_live_view, "~> 0.20"}  # For real-time UI
     ]
   end
   ```

### Phase 2: Migrate Core Logic

1. **Port Claude service** → `AgentWorker`
   - Move subprocess spawning to Port
   - Implement JSON streaming parser
   - Add state management

2. **Port state management** → GenServer or ETS
   - Replace file-based storage with ETS/Mnesia
   - Or keep file storage with File module

3. **Port SAM pattern concepts** → OTP principles
   - Actions → GenServer calls/casts
   - Model → GenServer state
   - State representation → Pattern matching

### Phase 3: Create API Layer

Choose one of these options:

#### Option A: Keep Electron, Add HTTP Backend

```elixir
# Add Phoenix API
mix phx.new puffin_agents_api --no-html --no-assets
```

Update Electron IPC to use HTTP:
```javascript
// src/main/ipc-handlers.js
ipcMain.handle('claude:submit', async (event, {prompt, branchId}) => {
  const response = await fetch('http://localhost:4000/api/agents/submit', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({agent_id: agentId, prompt})
  });
  return response.json();
});
```

#### Option B: Replace with Phoenix LiveView

```elixir
# lib/puffin_agents_web/live/agent_live.ex
defmodule PuffinAgentsWeb.AgentLive do
  use PuffinAgentsWeb, :live_view
  
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(PuffinAgents.PubSub, "agents")
    agents = PuffinAgents.AgentSupervisor.list_agents()
    {:ok, assign(socket, agents: agents)}
  end
  
  def handle_info({:agent_update, data}, socket) do
    # Update UI in real-time
    {:noreply, update_agents(socket, data)}
  end
end
```

### Phase 4: Data Migration

1. **Export existing state**
   ```javascript
   // Node.js script to export data
   const fs = require('fs');
   const puffinState = require('./src/main/puffin-state');
   
   async function exportData() {
     const state = await puffinState.open('./project');
     fs.writeFileSync('export.json', JSON.stringify(state, null, 2));
   }
   ```

2. **Import into Elixir**
   ```elixir
   # Elixir script to import
   defmodule PuffinAgents.Import do
     def import_from_nodejs(json_file) do
       data = File.read!(json_file) |> Jason.decode!()
       
       # Transform and store
       agent_id = data["agentId"]
       PuffinAgents.StateStore.save_state(agent_id, data)
     end
   end
   ```

### Phase 5: Testing

1. **Parallel Running**
   - Run both versions side-by-side
   - Compare outputs for same prompts
   - Verify state consistency

2. **Performance Testing**
   ```elixir
   # Load test with multiple agents
   defmodule PuffinAgents.LoadTest do
     def run do
       {:ok, agent_ids} = PuffinAgents.AgentSupervisor.spawn_population(
         population_size: 100,
         project_path: "/test/project"
       )
       
       # Submit same prompt to all
       Enum.each(agent_ids, fn id ->
         PuffinAgents.AgentWorker.submit_prompt(id, "Test prompt")
       end)
     end
   end
   ```

### Phase 6: Deployment

1. **Package as Release**
   ```bash
   MIX_ENV=prod mix release
   _build/prod/rel/puffin_agents/bin/puffin_agents start
   ```

2. **Deploy with Docker**
   ```bash
   docker build -t puffin-agents .
   docker run -p 4000:4000 puffin-agents
   ```

3. **Deploy to Kubernetes**
   ```bash
   kubectl apply -f k8s/puffin-agents.yaml
   ```

## Feature Parity Checklist

Core Features:
- [ ] Claude CLI subprocess management
- [ ] JSON streaming parser
- [ ] Session management and resumption
- [ ] Conversation history storage
- [ ] Tool usage tracking
- [ ] Project configuration
- [ ] Branch-based organization

New Features (Elixir-specific):
- [ ] Multiple concurrent agents
- [ ] Fault tolerance and supervision
- [ ] Evolutionary algorithms
- [ ] Distributed deployment
- [ ] Real-time monitoring
- [ ] Horizontal scaling

## Hybrid Approach

You can run both versions simultaneously:

```
┌─────────────────────┐
│  Electron Frontend  │ ← Keep for familiar UI
│  (Original Puffin)  │
└──────────┬──────────┘
           │ HTTP/WS
           ▼
┌─────────────────────┐
│  Elixir Backend     │ ← Add for multi-agent support
│  (Puffin Agents)    │
└─────────────────────┘
```

Benefits:
- Gradual migration
- Best of both worlds
- Easier rollback if needed

## Performance Comparison

Expected improvements with Elixir:

| Metric | Node.js | Elixir | Improvement |
|--------|---------|--------|-------------|
| **Concurrent Agents** | 1 | 100+ | 100x |
| **Memory per Agent** | ~50 MB | ~2 MB | 25x |
| **Agent Spawn Time** | ~500ms | ~10ms | 50x |
| **Fault Recovery** | Manual | Automatic | ∞ |
| **Horizontal Scaling** | Difficult | Native | ✓ |

## Troubleshooting

### Issue: Port Communication Errors

**Problem**: Agent can't communicate with Claude CLI

**Solution**:
```elixir
# Check Claude binary exists
System.find_executable("claude")

# Verify PATH
System.get_env("PATH")

# Test direct spawn
Port.open({:spawn_executable, "claude"}, [:binary, {:args, ["--version"]}])
```

### Issue: High Memory Usage

**Problem**: Many agents consuming too much memory

**Solution**:
```elixir
# Limit population size
max_agents = 50

# Use memory monitoring
:erlang.system_monitor(self(), [:busy_port, :busy_dist_port])

# Add hibernation
def handle_info(:timeout, state) do
  {:noreply, state, :hibernate}
end
```

### Issue: State Loss on Crash

**Problem**: Agent state not persisting across restarts

**Solution**:
```elixir
# Use persistent storage
defmodule PuffinAgents.AgentWorker do
  def init(opts) do
    # Load from disk on init
    state = load_state_from_disk(opts[:agent_id])
    {:ok, state}
  end
  
  def handle_cast({:submit_prompt, _, _}, state) do
    # Save after each operation
    save_state_to_disk(state)
    {:noreply, state}
  end
end
```

## Getting Help

- **Elixir Forum**: https://elixirforum.com
- **Elixir Slack**: https://elixir-slackin.herokuapp.com
- **GitHub Issues**: Open an issue in the Puffin repository

## Next Steps

1. Read the [Elixir README](README_ELIXIR.md)
2. Try the examples in `examples/`
3. Set up development environment
4. Start with a small pilot project
5. Gradually migrate features

## Resources

- [Elixir Getting Started](https://elixir-lang.org/getting-started/introduction.html)
- [Phoenix Framework](https://www.phoenixframework.org/)
- [OTP Design Principles](https://erlang.org/doc/design_principles/users_guide.html)
- [Elixir School](https://elixirschool.com/)
