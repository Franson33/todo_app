defmodule Todo.Cache do
  use GenServer

  def init(_) do
    IO.puts("Starting to-do cache.")

    {:ok, %{}}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def server_process(list_name, initial_entries \\ []) do
    GenServer.call(__MODULE__, {:server_process, list_name, initial_entries})
  end

  def handle_call({:server_process, list_name, initial_entries}, _from, todo_servers) do
    case Map.fetch(todo_servers, list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        Todo.Server.start_link(list_name, initial_entries)
        |> then(fn {:ok, new_server} ->
          {:reply, new_server, Map.put(todo_servers, list_name, new_server)}
        end)
    end
  end
end
