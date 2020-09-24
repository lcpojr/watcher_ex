defmodule Authenticator.Sessions.Commands.GetSession do
  @moduledoc """
  Gets a session by the given filters.
  """

  require Logger

  alias Authenticator.Sessions
  alias Authenticator.Sessions.Cache
  alias Authenticator.Sessions.Commands.Inputs.GetSession
  alias Authenticator.Sessions.Schemas.Session

  @typedoc "All possible responses"
  @type possible_responses :: {:ok, Session.t()} | {:error, :not_found}

  @doc "Returns a session using the given filters"
  @spec execute(input :: GetSession.t() | map()) :: possible_responses()
  def execute(%GetSession{jti: jti} = input) do
    Logger.info("Getting subject session")

    jti
    |> Cache.get()
    |> case do
      nil ->
        Logger.info("Session not found on cache")
        get_from_datatabase(input)

      %Session{} = session ->
        Logger.info("Session #{session.id} found on cache")
        session
    end
  end

  def execute(params) when is_map(params) do
    params
    |> GetSession.cast_and_apply()
    |> case do
      {:ok, %GetSession{} = input} -> execute(input)
      error -> error
    end
  end

  defp get_from_datatabase(input) do
    input
    |> GetSession.cast_to_list()
    |> Sessions.get_by()
    |> case do
      %Session{} = session ->
        Logger.info("Session #{session.id} got with success")
        {:ok, session}

      nil ->
        Logger.error("Failed to get session because it was not found")
        {:error, :not_found}
    end
  end
end
