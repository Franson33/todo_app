defmodule Todo.Server do
  use Agent, restart: :temporary

  def start_link({list_name, initial_entries}) do
    Agent.start_link(
      fn ->
        IO.puts("Starting todo server for #{list_name}")

        (Todo.Database.get(list_name) || Todo.List.new(initial_entries))
        |> then(&{list_name, &1})
      end,
      name: via_tuple(list_name)
    )
  end

  def entries(todo_server, date) do
    Agent.get(
      todo_server,
      fn {_name, todo_list} ->
        Todo.List.entries(todo_list, date)
      end
    )
  end

  def add_entry(todo_server, new_entry) do
    Agent.cast(
      todo_server,
      fn {name, todo_list} ->
        Todo.List.add_entry(todo_list, new_entry)
        |> tap(&Todo.Database.store(name, &1))
        |> then(&{name, &1})
      end
    )
  end

  def update_entry(todo_server, id, updater) do
    Agent.cast(
      todo_server,
      fn {name, todo_list} ->
        Todo.List.update_entry(todo_list, id, updater)
        |> tap(&Todo.Database.store(name, &1))
        |> then(&{name, &1})
      end
    )
  end

  def delete_entry(todo_server, id) do
    Agent.cast(
      todo_server,
      fn {name, todo_list} ->
        Todo.List.delete_entry(todo_list, id)
        |> tap(&Todo.Database.store(name, &1))
        |> then(&{name, &1})
      end
    )
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end
