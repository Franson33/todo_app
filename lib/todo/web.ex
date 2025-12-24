defmodule Todo.Web do
  def child_spec(_) do
    {
      Plug.Cowboy,
      scheme: :http, options: [port: 5454], plug: __MODULE__
    }
  end
end
