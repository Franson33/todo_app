defmodule Todo.Cache do
  use GenServer

  def init(_) do
    Todo.Database.start()
    {:ok, %{}}
  end

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def server_process(cache_pid, list_name, initial_entries \\ []) do
    GenServer.call(cache_pid, {:server_process, list_name, initial_entries})
  end

  def handle_call({:server_process, list_name, initial_entries}, _from, todo_servers) do
    case Map.fetch(todo_servers, list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        Todo.Server.start(list_name, initial_entries)
        |> then(fn {:ok, new_server} ->
          {:reply, new_server, Map.put(todo_servers, list_name, new_server)}
        end)
    end
  end
end
