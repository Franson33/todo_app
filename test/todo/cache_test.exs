defmodule Todo.CacheTest do
  use ExUnit.Case

  setup do
    {:ok, cache} = Todo.Cache.start()

    on_exit(fn ->
      if Process.alive?(cache) do
        Process.exit(cache, :kill)
      end
    end)

    %{cache: cache}
  end

  test "server_process", %{cache: cache} do
    bob_pid = Todo.Cache.server_process(cache, "bob")

    assert bob_pid != Todo.Cache.server_process(cache, "alice")
    assert bob_pid == Todo.Cache.server_process(cache, "bob")
  end

  test "to-do operations", %{cache: cache} do
    alice = Todo.Cache.server_process(cache, "alice")
    Todo.Server.add_entry(alice, %{date: ~D[2025-10-27], title: "Play game"})

    entries = Todo.Server.entries(alice, ~D[2025-10-27])
    assert [%{date: ~D[2025-10-27], title: "Play game"}] = entries
  end
end
