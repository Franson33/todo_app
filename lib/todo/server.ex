defmodule Todo.Server do
  use GenServer, restart: :temporary

  def init({list_name, initial_entries}) do
    IO.puts("Strting to-do server for #{list_name}.")

    {:ok, {list_name, initial_entries}, {:continue, :init}}
  end

  def handle_continue(:init, {list_name, initial_entries}) do
    (Todo.Database.get(list_name) || Todo.List.new(initial_entries))
    |> then(&{:noreply, {list_name, &1}})
  end

  def start_link({list_name, initial_entries}) do
    GenServer.start_link(__MODULE__, {list_name, initial_entries}, name: via_tuple(list_name))
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end

  def add_entry(pid, entry) do
    GenServer.cast(pid, {:add_entry, entry})
  end

  def update_entry(pid, id, updater) do
    GenServer.cast(pid, {:update_entry, id, updater})
  end

  def delete_entry(pid, id) do
    GenServer.cast(pid, {:delete_entry, id})
  end

  def handle_call({:entries, date}, _from, {name, list}) do
    {:reply, Todo.List.entries(list, date), {name, list}}
  end

  def handle_cast({:add_entry, entry}, {list_name, list}) do
    Todo.List.add_entry(list, entry)
    |> tap(&Todo.Database.store(list_name, &1))
    |> then(&{:noreply, {list_name, &1}})
  end

  def handle_cast({:update_entry, id, updater}, {list_name, list}) do
    Todo.List.update_entry(list, id, updater)
    |> tap(&Todo.Database.store(list_name, &1))
    |> then(&{:noreply, {list_name, &1}})
  end

  def handle_cast({:delete_entry, id}, {list_name, list}) do
    Todo.List.delete_entry(list, id)
    |> tap(&Todo.Database.store(list_name, &1))
    |> then(&{:noreply, {list_name, &1}})
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end
