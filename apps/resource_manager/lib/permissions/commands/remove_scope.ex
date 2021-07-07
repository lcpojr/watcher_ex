defmodule ResourceManager.Permissions.Commands.RemoveScope do
  @moduledoc """
  Command for removing scopes from the identity.
  """

  require Logger

  alias ResourceManager.Identities.Schemas.{ClientApplication, User}
  alias ResourceManager.Permissions.Schemas.{ClientApplicationScope, UserScope}
  alias ResourceManager.Repo

  @doc "Remove scopes from the identity"
  @spec execute(identity :: User.t() | ClientApplication.t(), scopes :: list(String.t())) :: :ok
  def execute(%User{} = user, scopes) when is_list(scopes) do
    Logger.debug("Removing scopes from user #{user.id}")

    {qtd, _} =
      [user_id: user.id, scope_id_in: scopes]
      |> UserScope.query()
      |> Repo.delete_all()

    Logger.debug("Succeeds in removing scopes #{qtd} from user #{user.id}")
    :ok
  end

  def execute(%ClientApplication{} = app, scopes) when is_list(scopes) do
    Logger.debug("Removing scopes from client application #{app.id}")

    {qtd, _} =
      [client_application_id: app.id, scope_id_in: scopes]
      |> ClientApplicationScope.query()
      |> Repo.delete_all()

    Logger.debug("Succeeds in removing scopes #{qtd} from client application #{app.id}")
    :ok
  end
end
