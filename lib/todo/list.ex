defmodule Todo.List do
  @type entry :: %{
          required(:date) => Date.t(),
          required(:title) => String.t(),
          optional(:id) => integer()
        }

  @type t :: %__MODULE__{
          next_id: integer(),
          entries: %{optional(integer()) => entry()}
        }
  defstruct next_id: 1, entries: %{}

  @spec new([entry()]) :: t
  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %Todo.List{},
      &add_entry(&2, &1)
    )
  end

  @spec add_entry(t, entry()) :: t
  def add_entry(list, entry)

  def add_entry(%Todo.List{entries: entries, next_id: id} = list, entry) do
    new_entries =
      entry
      |> Map.put(:id, id)
      |> then(&Map.put(entries, id, &1))

    %Todo.List{list | entries: new_entries, next_id: id + 1}
  end

  @spec entries(t, Date.t()) :: [entry()]
  def entries(list, date) do
    list.entries
    |> Map.values()
    |> Enum.filter(&(&1.date == date))
  end

  @spec update_entry(t, integer(), (entry() -> entry())) :: t
  def update_entry(%{entries: entries} = list, id, updater) do
    case Map.fetch(entries, id) do
      :error ->
        list

      {:ok, prev_entry} ->
        prev_entry
        |> updater.()
        |> then(&Map.put(entries, &1.id, &1))
        |> then(&%Todo.List{list | entries: &1})
    end
  end

  @spec delete_entry(t, integer()) :: t
  def delete_entry(%Todo.List{entries: entries} = list, id) do
    entries
    |> then(&Map.delete(&1, id))
    |> then(&%Todo.List{list | entries: &1})
  end
end
