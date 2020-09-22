defmodule RestAPI.Controllers.Public.Tokens do
  @moduledoc false

  use RestAPI.Controller, :controller

  alias RestAPI.Ports.Authenticator
  alias RestAPI.Views.Tokens

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
    |> Authenticator.sign_in_resource_owner()
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
    |> Authenticator.sign_in_refresh_token()
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
end
