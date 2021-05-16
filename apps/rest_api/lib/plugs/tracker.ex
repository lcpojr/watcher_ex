defmodule RestAPI.Plugs.Tracker do
  @moduledoc """
  Provides data for tracking the receveid requests into
  """

  require Logger

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{} = conn, _opts) do
    traking_data = %{
      "ip_address" => get_remote_ip(conn),
      "user_agent" => get_user_agent(conn),
      "request_id" => get_request_id(conn)
    }

    Logger.metadata(traking_data)

    put_private(conn, :tracking, traking_data)
  end

  defp get_remote_ip(conn) do
    conn.remote_ip
    |> :inet_parse.ntoa()
    |> to_string()
  end

  defp get_user_agent(conn) do
    conn
    |> get_req_header("user-agent")
    |> case do
      [] -> nil
      [user_agent | _] -> user_agent
    end
  end

  defp get_request_id(conn) do
    conn
    |> get_req_header("request-id")
    |> case do
      [] -> nil
      [request_id | _] -> request_id
    end
  end
end
