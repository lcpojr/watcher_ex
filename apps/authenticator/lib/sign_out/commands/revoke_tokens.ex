defmodule Authenticator.SignOut.Commands.RevokeTokens do
  @moduledoc """
  Revoke access token and refresh token sessions
  """

  alias Authenticator.Repo
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, RefreshToken}
  alias Authenticator.SignOut.Commands.Inputs.RevokeTokens
  alias Authenticator.SignOut.Commands.SignOutSession

  require Logger

  @typedoc "All possible command error reasons"
  @type possible_errors ::
          Ecto.Changeset.t()
          | :delete_cache_failed
          | :not_active
          | :not_active
          | :anauthenticated

  @typedoc "All possible command responses"
  @type possible_responses ::
          {:ok, {access_session :: Session.t() | nil, refresh_session :: Session.t() | nil}}
          | {:error, possible_errors()}

  @doc "Revoke the subject access token and/or refresh token sessions."
  @spec execute(input :: RevokeTokens.t()) :: possible_responses()
  def execute(%RevokeTokens{access_token: access_token, refresh_token: refresh_token}) do
    Repo.execute_transaction(fn ->
      with {:ok, access_session} <- revoke_token(access_token, AccessToken),
           {:ok, refresh_session} <- revoke_token(refresh_token, RefreshToken) do
        {:ok, {access_session, refresh_session}}
      end
    end)
  end

  defp revoke_token(nil, _module), do: {:ok, nil}

  defp revoke_token(token, module) when is_binary(token) and is_atom(module) do
    with {:token, {:ok, %{"jti" => jti}}} <- {:token, module.verify_and_validate(token)},
         {:session, {:ok, session}} <- {:session, SignOutSession.execute(jti)} do
      {:ok, session}
    else
      {:token, {:error, reason}} ->
        Logger.error("Failed to validate token #{inspect(module)} because #{inspect(reason)}")
        {:error, :anauthenticated}

      {:session, {:error, r} = error} ->
        Logger.error("Failed to revoke session token #{inspect(module)} because #{inspect(r)}")
        error
    end
  end
end
