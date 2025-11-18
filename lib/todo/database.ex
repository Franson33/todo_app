defmodule Todo.Database do
  alias Todo.DatabaseWorker

  @db_folder "./persist"
  @pool_size 3

  def start_link do
    File.mkdir_p!(@db_folder)

    Enum.map(1..@pool_size, &worker_spec/1)
    |> Supervisor.start_link(strategy: :one_for_one)
  end

  def store(key, data) do
    key
    |> choose_worker()
    |> DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker()
    |> DatabaseWorker.get(key)
  end

  def handle_call({:choose_worker, key}, _from, processes) do
    key
    |> :erlang.phash2(3)
    |> then(&Map.fetch!(processes, &1))
    |> then(&{:reply, &1, processes})
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  defp choose_worker(key) do
    :erlang.phash2(key, @pool_size) + 1
  end

  defp worker_spec(worker_id) do
    {Todo.DatabaseWorker, {@db_folder, worker_id}}
    |> Supervisor.child_spec(id: worker_id)
  end
end

defmodule Todo.DatabaseWorker do
  use GenServer

  def start_link({db_folder, worker_id}) do
    GenServer.start_link(
      __MODULE__,
      db_folder,
      name: via_tuple(worker_id)
    )
  end

  def init(db_folder) do
    IO.puts("Strting database worker")

    File.mkdir_p!(db_folder)

    {:ok, db_folder}
  end

  def store(worker_id, key, data) do
    GenServer.cast(via_tuple(worker_id), {:store, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(via_tuple(worker_id), {:get, key})
  end

  def handle_cast({:store, key, data}, db_folder) do
    spawn(fn ->
      key
      |> file_name(db_folder)
      |> File.write!(:erlang.term_to_binary(data))
    end)

    {:noreply, db_folder}
  end

  def handle_call({:get, key}, caller, db_folder) do
    spawn(fn ->
      key
      |> file_name(db_folder)
      |> File.read()
      |> then(fn
        {:ok, content} -> :erlang.binary_to_term(content)
        _ -> nil
      end)
      |> then(&GenServer.reply(caller, &1))
    end)

    {:noreply, db_folder}
  end

  defp file_name(key, db_folder) do
    Path.join(db_folder, to_string(key))
  end

  defp via_tuple(worker_id) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, worker_id})
  end
end
