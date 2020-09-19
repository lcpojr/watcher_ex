defmodule Authenticator.Sessions.Commands.GetSession do
  @moduledoc """
  Gets a session by the given filters.
  """

  require Logger

  alias Authenticator.Sessions.Commands.Inputs.GetSession
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions

  @typedoc "All possible responses"
  @type possible_responses :: {:ok, Session.t()} | {:error, :not_found}

  @doc "Returns a session using the given filters"
  @spec execute(input :: GetSession.t() | map()) :: possible_responses()
  def execute(%GetSession{} = input) do
    Logger.info("Getting subject session")

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

  def execute(params) when is_map(params) do
    params
    |> GetSession.cast_and_apply()
    |> case do
      {:ok, %GetSession{} = input} -> execute(input)
      error -> error
    end
  end
end
