import Config

http_port =
  if config_env() != :test,
    do: System.get_env("TODO_HTTP_PORT", "5454"),
    else: System.get_env("TODO_TEST_HTTP_PORT", "5455")

config :todo_app,
  http_port: String.to_integer(http_port),
  db_folder: "./persist/#{config_env()}"
