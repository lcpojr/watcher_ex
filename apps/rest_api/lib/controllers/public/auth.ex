defmodule RestAPI.Controllers.Public.Auth do
  @moduledoc false

  use RestAPI.Controller, :controller

  alias Authenticator.SignIn.Commands.Inputs.{
    AuthorizationCode,
    ClientCredentials,
    RefreshToken,
    ResourceOwner
  }

  alias RestAPI.Ports.Authenticator, as: Commands
  alias RestAPI.Views.Public.Auth

  action_fallback RestAPI.Controllers.Fallback

  @doc """
  Sign in an identity by using one of the accepted flows.

  The accepted flow are:
    - Resource Owner (Authenticates using username and password);
    - Refresh Token (Authenticates using an refresh token);
    - Client Credentials (Authenticates using client_id and secret);
  """
  @spec token(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def token(conn, %{"grant_type" => "password"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- ResourceOwner.cast_and_apply(params),
         {:ok, response} <- Commands.sign_in_resource_owner(input) do
      conn
      |> put_view(Auth)
      |> put_status(200)
      |> render("token.json", response: response)
    end
  end

  def token(conn, %{"grant_type" => "refresh_token"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- RefreshToken.cast_and_apply(params),
         {:ok, response} <- Commands.sign_in_refresh_token(input) do
      conn
      |> put_view(Auth)
      |> put_status(200)
      |> render("token.json", response: response)
    end
  end

  def token(conn, %{"grant_type" => "client_credentials"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- ClientCredentials.cast_and_apply(params),
         {:ok, response} <- Commands.sign_in_client_credentials(input) do
      conn
      |> put_view(Auth)
      |> put_status(200)
      |> render("token.json", response: response)
    end
  end

  def token(conn, %{"grant_type" => "authorization_code"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- AuthorizationCode.cast_and_apply(params),
         {:ok, response} <- Commands.sign_in_authorization_code(input) do
      conn
      |> put_view(Auth)
      |> put_status(200)
      |> render("token.json", response: response)
    end
  end

  @doc "Logout the authenticated subject session."
  @spec logout(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def logout(%{private: %{session: session}} = conn, _params) do
    session.jti
    |> Commands.sign_out_session()
    |> case do
      {:ok, _any} -> send_resp(conn, :no_content, "")
      {:error, _reason} = error -> error
    end
  end

  @doc "Logout subject authenticated sessions."
  @spec logout_all_sessions(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def logout_all_sessions(%{private: %{session: session}} = conn, _params) do
    session.subject_id
    |> Commands.sign_out_all_sessions(session.subject_type)
    |> case do
      {:ok, _any} -> send_resp(conn, :no_content, "")
      {:error, _reason} = error -> error
    end
  end
end
