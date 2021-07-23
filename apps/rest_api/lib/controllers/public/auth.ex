defmodule RestAPI.Controllers.Public.Auth do
  @moduledoc false

  use RestAPI.Controller, :controller

  alias Authenticator.SignIn.Commands.Inputs.{
    AuthorizationCode,
    ClientCredentials,
    RefreshToken,
    ResourceOwner
  }

  alias Authenticator.SignOut.Commands.Inputs.RevokeTokens
  alias Authorizer.Rules.Commands.Inputs.AuthorizationCodeSignIn
  alias RestAPI.Ports.{Authenticator, Authorizer}
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
         {:ok, response} <- Authenticator.sign_in_resource_owner(input) do
      conn
      |> put_view(Auth)
      |> put_status(200)
      |> render("token.json", response: response)
    end
  end

  def token(conn, %{"grant_type" => "refresh_token"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- RefreshToken.cast_and_apply(params),
         {:ok, response} <- Authenticator.sign_in_refresh_token(input) do
      conn
      |> put_view(Auth)
      |> put_status(200)
      |> render("token.json", response: response)
    end
  end

  def token(conn, %{"grant_type" => "client_credentials"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- ClientCredentials.cast_and_apply(params),
         {:ok, response} <- Authenticator.sign_in_client_credentials(input) do
      conn
      |> put_view(Auth)
      |> put_status(200)
      |> render("token.json", response: response)
    end
  end

  def token(conn, %{"grant_type" => "authorization_code"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- AuthorizationCode.cast_and_apply(params),
         {:ok, response} <- Authenticator.sign_in_authorization_code(input) do
      conn
      |> put_view(Auth)
      |> put_status(200)
      |> render("token.json", response: response)
    end
  end

  @doc "Revoke the given tokens sessions"
  @spec logout(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def revoke(conn, params) do
    with {:ok, input} <- RevokeTokens.cast_and_apply(params),
         {:ok, _any} <- Commands.revoke_tokens(input) do
      send_resp(conn, :ok, "")
    end
  end

  @doc """
  Authorize an client to sign in the user later by using an authorization code.

  This flow should only be used on authorization code grants.
  """
  @spec authorize(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def authorize(%{private: %{session: session}} = conn, params) do
    with {:ok, input} <- AuthorizationCodeSignIn.cast_and_apply(params),
         {:ok, resp} <- Authorizer.authorize_authorization_code_sign_in(input, session.subject_id) do
      if not is_nil(input.redirect_uri) and not is_nil(input.state) do
        redirect(
          conn,
          external: "#{input.redirect_uri}?code=#{resp.authorization_code}&state=#{input.state}"
        )
      else
        conn
        |> put_view(Auth)
        |> put_status(200)
        |> render("authorize.json", response: resp, state: input.state)
      end
    end
  end
end
