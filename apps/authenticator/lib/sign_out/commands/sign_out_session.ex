defmodule Authenticator.Sessions.Commands.SignOutSession do
  @moduledoc """
  Invalidates the given session.
  """

  require Logger

  alias Authenticator.{Repo, Sessions}
  alias Authenticator.Sessions.Cache
  alias Authenticator.Sessions.Schemas.Session
  alias Ecto.Multi

  @typedoc "All possible responses"
  @type possible_responses ::
          {:ok, Session.t()}
          | {:error, Ecto.Changeset.t() | :delete_cache_failed | :not_active | :not_active}

  @doc "Sign out the given session by invalidating it's status"
  @spec execute(session_or_jti :: Session.t() | String.t()) :: possible_responses()
  def execute(%Session{status: "active"} = session) do
    Multi.new()
    |> Multi.run(:invalidate, fn _repo, _changes ->
      Sessions.update(session, %{status: "invalidated"})
    end)
    |> Multi.run(:delete_cache, fn _repo, %{invalidate: session} ->
      session.jti
      |> Cache.delete()
      |> case do
        key when is_binary(key) -> {:ok, :deleted}
        _any -> {:error, :delete_cache_failed}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{invalidate: %Session{} = session}} ->
        Logger.info("Succeeds in logout session #{session.id}")
        {:ok, session}

      {:error, step, err, _changes} ->
        Logger.error("Failed to logout session in step #{inspect(step)}", reason: err)
        {:error, err}
    end
  end

  def execute(jti) when is_binary(jti) do
    [jti: jti]
    |> Sessions.get_by()
    |> case do
      %Session{status: "active"} = session -> execute(session)
      %Session{} -> {:error, :not_active}
      _any -> {:error, :not_found}
    end
  end

  def execute(_any), do: {:error, :invalid_params}
end
