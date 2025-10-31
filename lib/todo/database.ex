defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    File.mkdir_p!(@db_folder)
    {:ok, nil}
  end

  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def handle_cast({:store, key, data}, state) do
    spawn(fn ->
      key
      |> file_name()
      |> File.write!(:erlang.term_to_binary(data))
    end)

    {:noreply, state}
  end

  def handle_call({:get, key}, caller, state) do
    spawn(fn ->
      key
      |> file_name()
      |> File.read()
      |> then(fn
        {:ok, content} -> :erlang.binary_to_term(content)
        _ -> nil
      end)
      |> then(&GenServer.reply(caller, &1))
    end)

    {:noreply, state}
  end

  def handle_call({:get, key}, _, state) do
    key
    |> file_name()
    |> File.read()
    |> then(fn
      {:ok, content} -> :erlang.binary_to_term(content)
      _ -> nil
    end)
    |> then(&{:reply, &1, state})
  end

  defp file_name(key) do
    Path.join(@db_folder, to_string(key))
  end
end
