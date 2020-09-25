defmodule Authenticator.Sessions.Commands.LogoutSession do
  @moduledoc """
  Invalidates the given session.
  """

  require Logger

  alias Authenticator.{Repo, Sessions}
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Cache
  alias Ecto.Multi

  @typedoc "All possible responses"
  @type possible_responses ::
          {:ok, Session.t()}
          | {:error, Ecto.Changeset.t() | :delete_cache_failed | :invalid_status}

  @doc "Logout the given session by invalidating it's status"
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
      %Session{} = session -> execute(session)
      nil -> {:error, :not_found}
    end
  end

  def execute(%Session{status: status}) when status != "active", do: {:error, :invalid_status}
  def execute(_any), do: {:error, :invalid_params}
end
