defmodule Authenticator.SignOut.Commands.RevokeTokens do
  @moduledoc """
  Revoke access token and refresh token sessions
  """

  alias Authenticator.Repo
  alias Authenticator.Sessions.Commands.GetSession
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
      with {:ok, access_session} <- revoke_token(access_token, "access_token"),
           {:ok, refresh_session} <- revoke_token(refresh_token, "refresh_token") do
        {:ok, {access_session, refresh_session}}
      end
    end)
  end

  defp revoke_token(nil, _type), do: {:ok, nil}

  defp revoke_token(token, type) do
    with {:token, {:ok, %{"jti" => jti}}} <- {:token, validate_token(token, type)},
         {:session, {:ok, session}} <- {:session, GetSession.execute(%{jti: jti, type: type})},
         {:revoke, {:ok, session}} <- {:revoke, SignOutSession.execute(session)} do
      {:ok, session}
    else
      {:token, {:error, reason}} ->
        Logger.error("Failed to validate #{inspect(type)} because #{inspect(reason)}")
        {:error, :anauthenticated}

      {:session, {:error, :not_found}} ->
        Logger.error("failed to get #{inspect(type)} session")
        {:error, :anauthenticated}

      {:revoke, {:error, reason} = error} ->
        Logger.error("Failed to revoke session #{inspect(type)} because #{inspect(reason)}")
        error
    end
  end

  defp validate_token(token, "access_token"), do: AccessToken.verify_and_validate(token)
  defp validate_token(token, "refres_token"), do: RefreshToken.verify_and_validate(token)
end
