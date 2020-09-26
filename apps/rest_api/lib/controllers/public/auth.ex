defmodule RestAPI.Controllers.Public.Auth do
  @moduledoc false

  use RestAPI.Controller, :controller

  alias RestAPI.Ports.Authenticator, as: Commands
  alias RestAPI.Views.Public.Tokens

  action_fallback RestAPI.Controllers.Fallback

  @doc """
  Sign in an identity by using one of the accepted flows.

  The accepted flow are:
    - Resource Owner (Authenticates using username and password);
    - Refresh Token (Authenticates using an refresh token);
  """
  @spec sign_in(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def sign_in(conn, %{"grant_type" => "password"} = params) do
    params
    |> Commands.sign_in_resource_owner()
    |> case do
      {:ok, response} ->
        conn
        |> put_status(:ok)
        |> put_view(Tokens)
        |> render("sign_in.json", response: response)

      {:error, _reason} = error ->
        error
    end
  end

  def sign_in(conn, %{"grant_type" => "refresh_token"} = params) do
    params
    |> Commands.sign_in_refresh_token()
    |> case do
      {:ok, response} ->
        conn
        |> put_status(:ok)
        |> put_view(Tokens)
        |> render("sign_in.json", response: response)

      {:error, _reason} = error ->
        error
    end
  end

  @doc "Logout the authenticated subject session."
  @spec sign_out(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def sign_out(%{private: %{session: session}} = conn, _params) do
    session.jti
    |> Commands.sign_out_session()
    |> case do
      {:ok, _count} -> send_resp(conn, :no_content, "")
      {:error, :not_active} -> send_resp(conn, :forbidden, "")
      {:error, :not_found} -> send_resp(conn, :not_found, "")
    end
  end

  @doc "Logout subject authenticated sessions."
  @spec sign_out_all_sessions(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def sign_out_all_sessions(%{private: %{session: session}} = conn, _params) do
    session.subject_id
    |> Commands.sign_out_all_sessions(session.subject_type)
    |> case do
      {:ok, _count} -> send_resp(conn, :no_content, "")
      {:error, :not_active} -> send_resp(conn, :forbidden, "")
      {:error, :not_found} -> send_resp(conn, :not_found, "")
    end
  end
end
