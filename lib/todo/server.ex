defmodule Todo.Server do
  use GenServer

  def init(initial_entries), do: {:ok, Todo.List.new(initial_entries)}

  def start(initial_entries \\ []) do
    GenServer.start(__MODULE__, initial_entries)
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

  def handle_call({:entries, date}, _, state) do
    {:reply, Todo.List.entries(state, date), state}
  end

  def handle_cast({:add_entry, entry}, state) do
    {:noreply, Todo.List.add_entry(state, entry)}
  end

  def handle_cast({:update_entry, id, updater}, state) do
    {:noreply, Todo.List.update_entry(state, id, updater)}
  end

  def handle_cast({:delete_entry, id}, state) do
    {:noreply, Todo.List.delete_entry(state, id)}
  end
end
