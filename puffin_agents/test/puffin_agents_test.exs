defmodule PuffinAgentsTest do
  use ExUnit.Case
  doctest PuffinAgents

  test "greets the world" do
    assert PuffinAgents.hello() == :world
  end
end
