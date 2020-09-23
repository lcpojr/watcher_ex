defmodule RestAPI.Controllers.Public.Sessions do
  @moduledoc false

  use RestAPI.Controller, :controller

  alias RestAPI.Ports.Authenticator, as: Commands

  action_fallback RestAPI.Controllers.Fallback

  @doc "Logout the authenticated subject session."
  @spec logout(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def logout(conn, _params) do
    conn
    |> Map.get(:private)
    |> Map.get(:session)
    |> Commands.logout_session()

    send_resp(conn, :no_content, "")
  end
end
