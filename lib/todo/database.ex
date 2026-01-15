defmodule Todo.Database do
  @pool_size 3

  def child_spec(_) do
    File.mkdir_p!(db_folder())

    %{
      id: __MODULE__,
      start: {
        :poolboy,
        :start_link,
        [
          [
            name: {:local, __MODULE__},
            worker_module: Todo.DatabaseWorker,
            size: @pool_size
          ],
          [db_folder()]
        ]
      },
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def store(key, data) do
    {_result, bad_nodes} =
      :rpc.multicall(
        __MODULE__,
        :store_local,
        [key, data],
        :timer.seconds(5)
      )

    Enum.each(bad_nodes, &IO.puts("Store failed on node #{&1}"))
    :ok
  end

  def store_local(key, data) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.store(worker_pid, key, data)
      end
    )
  end

  def get(key) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.get(worker_pid, key)
      end
    )
  end

  defp db_folder do
    base = Application.fetch_env!(:todo_app, :db_folder)
    node = Node.self() |> Atom.to_string()

    Path.join([base, node])
  end
end

defmodule Todo.DatabaseWorker do
  use GenServer

  def start_link(db_folder) do
    GenServer.start_link(__MODULE__, db_folder)
  end

  def init(db_folder) do
    IO.puts("Starting database worker")

    File.mkdir_p!(db_folder)

    {:ok, db_folder}
  end

  def store(pid, key, data) do
    GenServer.call(pid, {:store, key, data})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def handle_call({:store, key, data}, _caller, db_folder) do
    key
    |> file_name(db_folder)
    |> File.write!(:erlang.term_to_binary(data))

    {:reply, :ok, db_folder}
  end

  def handle_call({:get, key}, _caller, db_folder) do
    key
    |> file_name(db_folder)
    |> File.read()
    |> then(fn
      {:ok, content} -> :erlang.binary_to_term(content)
      _ -> nil
    end)
    |> then(&{:reply, &1, db_folder})
  end

  defp file_name(key, db_folder) do
    Path.join(db_folder, to_string(key))
  end
end
