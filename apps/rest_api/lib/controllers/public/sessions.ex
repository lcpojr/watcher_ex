defmodule RestAPI.Controllers.Public.Sessions do
  @moduledoc false

  use RestAPI.Controller, :controller

  alias RestAPI.Ports.Authenticator, as: Commands

  action_fallback RestAPI.Controllers.Fallback

  @doc "Logout the authenticated subject session."
  @spec logout(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def logout(%{private: %{session: session}} = conn, _params) do
    session.jti
    |> Commands.logout_session()
    |> case do
      {:ok, _count} -> send_resp(conn, :no_content, "")
      {:error, :not_active} -> send_resp(conn, :forbidden, "")
      {:error, :not_found} -> send_resp(conn, :not_found, "")
    end
  end

  @doc "Logout subject authenticated sessions."
  @spec logout_all_sessions(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def logout_all_sessions(%{private: %{session: session}} = conn, _params) do
    session.subject_id
    |> Commands.logout_all_sessions(session.subject_type)
    |> case do
      {:ok, _count} -> send_resp(conn, :no_content, "")
      {:error, :not_active} -> send_resp(conn, :forbidden, "")
      {:error, :not_found} -> send_resp(conn, :not_found, "")
    end
  end
end
