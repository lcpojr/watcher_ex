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
  alias RestAPI.Views.Public.SignIn

  action_fallback RestAPI.Controllers.Fallback

  @doc """
  Sign in an identity by using one of the accepted flows.

  The accepted flow are:
    - Resource Owner (Authenticates using username and password);
    - Refresh Token (Authenticates using an refresh token);
    - Client Credentials (Authenticates using client_id and secret);
  """
  @spec sign_in(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def sign_in(conn, %{"grant_type" => "password"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- ResourceOwner.cast_and_apply(params),
         {:ok, response} <- Commands.sign_in_resource_owner(input) do
      conn
      |> put_view(SignIn)
      |> put_status(200)
      |> render("sign_in.json", response: response)
    end
  end

  def sign_in(conn, %{"grant_type" => "refresh_token"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- RefreshToken.cast_and_apply(params),
         {:ok, response} <- Commands.sign_in_refresh_token(input) do
      conn
      |> put_view(SignIn)
      |> put_status(200)
      |> render("sign_in.json", response: response)
    end
  end

  def sign_in(conn, %{"grant_type" => "client_credentials"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- ClientCredentials.cast_and_apply(params),
         {:ok, response} <- Commands.sign_in_client_credentials(input) do
      conn
      |> put_view(SignIn)
      |> put_status(200)
      |> render("sign_in.json", response: response)
    end
  end

  def sign_in(conn, %{"grant_type" => "authorization_code"} = params) do
    params = Map.merge(params, conn.private.tracking)

    with {:ok, input} <- AuthorizationCode.cast_and_apply(params),
         {:ok, response} <- Commands.sign_in_authorization_code(input) do
      conn
      |> put_view(SignIn)
      |> put_status(200)
      |> render("sign_in.json", response: response)
    end
  end

  @doc "Logout the authenticated subject session."
  @spec sign_out(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def sign_out(%{private: %{session: session}} = conn, _params) do
    session.jti
    |> Commands.sign_out_session()
    |> parse_sign_out_response(conn)
  end

  @doc "Logout subject authenticated sessions."
  @spec sign_out_all_sessions(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def sign_out_all_sessions(%{private: %{session: session}} = conn, _params) do
    session.subject_id
    |> Commands.sign_out_all_sessions(session.subject_type)
    |> parse_sign_out_response(conn)
  end

  defp parse_sign_out_response({:ok, _any}, conn), do: send_resp(conn, :no_content, "")
  defp parse_sign_out_response({:error, :not_active}, conn), do: send_resp(conn, :forbidden, "")
  defp parse_sign_out_response({:error, :not_found}, conn), do: send_resp(conn, :not_found, "")
  defp parse_sign_out_response({:error, _any} = error, _conn), do: error
end
