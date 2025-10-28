defmodule Todo.Cache do
  use GenServer

  def init(_), do: {:ok, %{}}

  def start, do: GenServer.start(__MODULE__, nil, name: __MODULE__)

  def server_process(cache_pid, list_name) do
    GenServer.call(cache_pid, {:server_process, list_name})
  end

  def handle_call({:server_process, list_name}, _from, todo_servers) do
    case Map.fetch(todo_servers, list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        Todo.Server.start()
        |> then(fn {:ok, new_server} ->
          {:reply, new_server, Map.put(todo_servers, list_name, new_server)}
        end)
    end
  end
end
