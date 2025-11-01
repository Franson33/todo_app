defmodule Todo.Database do
  use GenServer
  alias Todo.DatabaseWorker

  @db_folder "./persist"

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    File.mkdir_p!(@db_folder)

    processes =
      for index <- 0..2, into: %{} do
        @db_folder
        |> DatabaseWorker.start()
        |> then(fn {:ok, pid} -> {index, pid} end)
      end

    {:ok, processes}
  end

  def store(key, data) do
    key
    |> choose_worker()
    |> then(&DatabaseWorker.store(&1, key, data))
  end

  def get(key) do
    key
    |> choose_worker()
    |> then(&DatabaseWorker.get(&1, key))
  end

  def choose_worker(key) do
    GenServer.call(__MODULE__, {:choose_worker, key})
  end

  def handle_call({:choose_worker, key}, _from, processes) do
    key
    |> :erlang.phash2(3)
    |> then(&Map.fetch!(processes, &1))
    |> then(&{:reply, &1, processes})
  end
end

defmodule Todo.DatabaseWorker do
  use GenServer

  def start(db_folder) do
    GenServer.start(__MODULE__, db_folder)
  end

  def init(db_folder) do
    File.mkdir_p!(db_folder)

    {:ok, db_folder}
  end

  def store(pid, key, data) do
    GenServer.cast(pid, {:store, key, data})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
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
end
