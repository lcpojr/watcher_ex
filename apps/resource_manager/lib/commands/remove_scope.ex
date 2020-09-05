defmodule ResourceManager.Commands.RemoveScope do
  @moduledoc """
  Command for removing scopes from the identity.
  """

  require Logger

  alias Ecto.Multi
  alias ResourceManager.Identity.Schemas.{ClientApplication, User}
  alias ResourceManager.Permissions.Schemas.{ClientApplicationScope, UserScope}
  alias ResourceManager.Repo

  @typedoc "All possible identities"
  @type identities :: User.t() | ClientApplication.t()

  @typedoc "All possible responses"
  @type possible_response :: {:ok, list(identities())} | {:error, Ecto.Changeset.t()}

  @doc "Remove scopes from the identity"
  @spec execute(identity :: identities(), scopes :: list(String.t())) :: possible_response()
  def execute(%User{} = user, scopes) when is_list(scopes) do
    Logger.info("Removing scopes from user #{user.id}")

    params = Enum.map(scopes, &build_params(user, &1))

    Multi.new()
    |> Multi.delete_all(:remove_consent, UserScope, params)
    |> Repo.transaction()
    |> case do
      {:ok, %{remove_consent: {_qtd, _any}}} ->
        Logger.info("Succeeds in removing scopes to user #{user.id}")
        :ok

      {:error, step, reason, _changes} ->
        Logger.error("Failed to remove scope in step #{inspect(step)}", reason: reason)
        {:error, reason}
    end
  end

  def execute(%ClientApplication{} = application, scopes) when is_list(scopes) do
    Logger.info("Removing scopes from client application #{application.id}")

    params = Enum.map(scopes, &build_params(application, &1))

    Multi.new()
    |> Multi.delete_all(:remove_consent, ClientApplicationScope, params)
    |> Repo.transaction()
    |> case do
      {:ok, %{remove_consent: {_qtd, _any}}} ->
        Logger.info("Succeeds in removing scopes to client application #{application.id}")
        :ok

      {:error, step, reason, _changes} ->
        Logger.error("Failed to remove scope in step #{inspect(step)}", reason: reason)
        {:error, reason}
    end
  end

  defp build_params(%User{id: user_id}, scope_id),
    do: %{scope_id: scope_id, user_id: user_id}

  defp build_params(%ClientApplication{id: client_application_id}, scope_id),
    do: %{scope_id: scope_id, client_application_id: client_application_id}
end
