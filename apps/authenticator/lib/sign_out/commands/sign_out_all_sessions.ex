defmodule Authenticator.Sessions.Commands.SignOutAllSessions do
  @moduledoc """
  Invalidates all subject sessions.
  """

  require Logger

  alias Authenticator.Repo
  alias Authenticator.Sessions.Manager
  alias Authenticator.Sessions.Schemas.Session
  alias Ecto.Multi

  @doc "Sign out all subject active sessions by invalidating it's status"
  @spec execute(subject_id :: String.t(), subject_type :: String.t()) :: {:ok, count :: integer()}
  def execute(subject_id, subject_type) when is_binary(subject_id) and is_binary(subject_type) do
    Multi.new()
    |> Multi.run(:invalidate, fn _repo, _changes ->
      [status: "active", subject_id: subject_id, subject_type: subject_type]
      |> Session.query()
      |> Repo.update_all(set: [status: "invalidated"])
      |> case do
        {count, _} when is_integer(count) -> {:ok, count}
        {:error, _reason} = error -> error
      end
    end)
    |> Multi.run(:delete_cache, fn _repo, _changes ->
      Manager.execute()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{invalidate: 0}} ->
        Logger.info("Succeeds on command but any active session was found")
        {:error, :not_active}

      {:ok, %{invalidate: count}} ->
        Logger.info("Succeeds in signing out #{inspect(count)} sessions")
        {:ok, count}

      {:error, step, err, _changes} ->
        Logger.error("Failed to signing out sessions in step #{inspect(step)}", reason: err)
        {:error, err}
    end
  end
end
