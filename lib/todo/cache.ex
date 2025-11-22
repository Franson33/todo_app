defmodule Todo.Cache do
  def start_link do
    IO.puts("Starting to-do cache.")

    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def server_process(list_name, initial_entries \\ []) do
    case start_child(list_name, initial_entries) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_child(list_name, initial_entries) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Todo.Server, {list_name, initial_entries}}
    )
  end
end
