defmodule PuffinAgents.Application do
  @moduledoc """
  OTP Application for Puffin Agents.
  
  Starts the supervision tree for managing multiple Claude agents
  with evolutionary capabilities.
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Puffin Agents application")
    
    children = [
      # Registry for agent discovery
      {Registry, keys: :unique, name: PuffinAgents.AgentRegistry},
      
      # PubSub for agent events
      {Phoenix.PubSub, name: PuffinAgents.PubSub},
      
      # Dynamic supervisor for agent workers
      PuffinAgents.AgentSupervisor,
      
      # State persistence (optional, can use Mnesia, ETS, or PostgreSQL)
      # PuffinAgents.StateStore,
      
      # API endpoint supervisor (if using Phoenix)
      # PuffinAgents.Endpoint
    ]

    opts = [strategy: :one_for_one, name: PuffinAgents.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
