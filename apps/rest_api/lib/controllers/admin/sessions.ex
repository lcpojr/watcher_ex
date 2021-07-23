defmodule RestAPI.Controller.Admin.Sessions do
  @moduledoc false

  use RestAPI.Controller, :controller

  action_fallback RestAPI.Controllers.Fallback

  @doc "Logout the authenticated subject session."
  @spec logout(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def logout(%{private: %{session: session}} = conn, _params) do
    session.jti
    |> Authenticator.sign_out_session()
    |> case do
      {:ok, _any} -> send_resp(conn, :no_content, "")
      {:error, _reason} = error -> error
    end
  end

  @doc "Logout subject authenticated sessions."
  @spec logout_all_sessions(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def logout_all_sessions(%{private: %{session: session}} = conn, _params) do
    session.subject_id
    |> Authenticator.sign_out_all_sessions(session.subject_type)
    |> case do
      {:ok, _any} -> send_resp(conn, :no_content, "")
      {:error, _reason} = error -> error
    end
  end
end
