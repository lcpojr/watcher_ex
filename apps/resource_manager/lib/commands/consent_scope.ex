defmodule ResourceManager.Commands.ConsentScope do
  @moduledoc """
  Command for consenting new scopes to the an identity.
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

  @doc "Consent new scopes to the identity"
  @spec execute(identity :: identities(), scopes :: list(String.t())) :: possible_response()
  def execute(%User{} = user, scopes) when is_list(scopes) do
    Logger.info("Consenting scopes to user #{user.id}")

    params = Enum.map(scopes, &build_params(user, &1))

    Multi.new()
    |> Multi.delete_all(:remove_consent, UserScope, params)
    |> Multi.insert_all(:consent_scopes, UserScope, params, returning: true)
    |> Repo.transaction()
    |> case do
      {:ok, %{consent_scopes: {_qtd, user_scopes}}} ->
        Logger.info("Succeeds in consenting scopes to user #{user.id}")
        {:ok, user_scopes}

      {:error, step, reason, _changes} ->
        Logger.error("Failed to consent scope in step #{inspect(step)}", reason: reason)
        {:error, reason}
    end
  end

  def execute(%ClientApplication{} = application, scopes) when is_list(scopes) do
    Logger.info("Consenting scopes to client application #{application.id}")

    params = Enum.map(scopes, &build_params(application, &1))

    Multi.new()
    |> Multi.delete_all(:remove_consent, ClientApplicationScope, params)
    |> Multi.insert_all(:consent_scopes, ClientApplicationScope, params, returning: true)
    |> Repo.transaction()
    |> case do
      {:ok, %{consent_scopes: {_qtd, application_scopes}}} ->
        Logger.info("Succeeds in consenting scopes to client application #{application.id}")
        {:ok, application_scopes}

      {:error, step, reason, _changes} ->
        Logger.error("Failed to consent scope in step #{inspect(step)}", reason: reason)
        {:error, reason}
    end
  end

  defp build_params(%User{id: user_id}, scope_id) do
    %{
      scope_id: scope_id,
      user_id: user_id,
      inserted_at: default_timestamp(),
      updated_at: default_timestamp()
    }
  end

  defp build_params(%ClientApplication{id: client_application_id}, scope_id) do
    %{
      scope_id: scope_id,
      client_application_id: client_application_id,
      inserted_at: default_timestamp(),
      updated_at: default_timestamp()
    }
  end

  defp default_timestamp, do: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
end
