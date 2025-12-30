defmodule Todo.Web do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post "/add_entry" do
    %{
      "list" => list_name,
      "title" => title,
      "date" => date_str
    } =
      Plug.Conn.fetch_query_params(conn).params

    date = date_str |> Date.from_iso8601!()

    list_name
    |> Todo.Cache.server_process()
    |> Todo.Server.add_entry(%{title: title, date: date})

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, "OK")
  end

  get "/entries" do
    %{
      "list" => list_name,
      "date" => date_str
    } = Plug.Conn.fetch_query_params(conn).params

    entries =
      list_name
      |> Todo.Cache.server_process()
      |> Todo.Server.entries(date_str |> Date.from_iso8601!())

    formatted_entries =
      entries
      |> Enum.map(&"#{&1.date} #{&1.title}")
      |> Enum.join("\n")

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, formatted_entries)
  end
end
