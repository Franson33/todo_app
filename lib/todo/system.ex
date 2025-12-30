defmodule Todo.System do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    Supervisor.init(
      [
        Todo.Metrics,
        Todo.ProcessRegistry,
        Todo.Cache,
        Todo.Database,
        {
          Plug.Cowboy,
          plug: Todo.Web, scheme: :http, options: [port: 5454]
        }
      ],
      strategy: :one_for_one
    )
  end
end
