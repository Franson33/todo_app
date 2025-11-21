defmodule Todo.Cache do
  def start_link do
    IO.puts("Starting to-do cache.")

    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  def start_child(list_name) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Todo.Server, list_name}
    )
  end

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  # TODO: Code below is legacy, refactor to dynamic supervisor
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
