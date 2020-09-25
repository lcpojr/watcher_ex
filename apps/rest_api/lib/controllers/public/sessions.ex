defmodule RestAPI.Controllers.Public.Sessions do
  @moduledoc false

  use RestAPI.Controller, :controller

  alias RestAPI.Ports.Authenticator, as: Commands

  action_fallback RestAPI.Controllers.Fallback

  @doc "Logout the authenticated subject session."
  @spec logout(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def logout(%Plug.Conn{private: %{session: session}} = conn, _params) do
    session.jti
    |> Commands.logout_session()
    |> case do
      {:ok, _count} -> send_resp(conn, :no_content, "")
      {:error, :invalid_status} -> send_resp(conn, :no_content, "")
      {:error, _reason} = error -> error
    end
  end

  @doc "Logout subject authenticated sessions."
  @spec logout_all_sessions(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def logout_all_sessions(%Plug.Conn{private: %{session: session}} = conn, _params) do
    session.subject_id
    |> Commands.logout_all_sessions(session.subject_type)
    |> case do
      {:ok, _count} -> send_resp(conn, :no_content, "")
      {:error, _reason} = error -> error
    end
  end
end
