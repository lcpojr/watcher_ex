defmodule RestAPI.Plugs.Authentication do
  @moduledoc """
  Provides authentication for public calls.
  """

  require Logger

  import Plug.Conn

  alias Authenticator.Sessions.Commands.GetSession
  alias Authenticator.Sessions.Tokens.AccessToken
  alias RestAPI.Controllers.Fallback

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{} = conn, _opts) do
    with {:header, [access_token | _]} <- {:header, get_req_header(conn, "authorization")},
         {:bearer, "Bearer " <> access_token} <- {:bearer, access_token},
         {:token, {:ok, claims}} <- {:token, AccessToken.verify_and_validate(access_token)},
         {:session, {:ok, session}} <- {:session, find_session(claims)} do
      put_private(conn, :session, build_payload(session))
    else
      {:header, []} ->
        Logger.info("Authorization header not found")
        Fallback.call(conn, {:error, :unauthenticated})

      {:bearer, _any} ->
        Logger.info("Token was not bearer type")
        Fallback.call(conn, {:error, :unauthenticated})

      {:token, {:error, reason}} ->
        Logger.info("Token is invalid", error: inspect(reason))
        Fallback.call(conn, {:error, :unauthenticated})

      {:session, _any} ->
        Logger.info("Session was not found")
        Fallback.call(conn, {:error, :unauthenticated})

      error ->
        Logger.error("Failed to authenticate because of an unknow error")
        Fallback.call(conn, error)
    end
  end

  defp find_session(%{"jti" => jti}), do: GetSession.execute(%{jti: jti})

  defp build_payload(session) when is_map(session) do
    %{
      id: session.id,
      jti: session.jti,
      subject_id: session.subject_id,
      subject_type: session.subject_type,
      expires_at: session.expires_at,
      scopes: parse_scopes(session.claims),
      azp: parse_azp(session.claims)
    }
  end

  defp parse_azp(%{"azp" => azp}) when is_binary(azp), do: azp
  defp parse_azp(_any), do: nil

  defp parse_scopes(%{"scope" => scope}) when is_binary(scope) do
    scope
    |> String.split(" ", trim: true)
    |> Enum.map(& &1)
  end

  defp parse_scopes(_any), do: []
end
