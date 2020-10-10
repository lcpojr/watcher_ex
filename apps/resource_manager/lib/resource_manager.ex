defmodule ResourceManager do
  @moduledoc """
  Application to deal with request's to the resource server.
  """

  alias ResourceManager.Credentials.Commands.PasswordIsAllowed
  alias ResourceManager.Identity.Commands.{CreateIdentity, GetIdentity}
  alias ResourceManager.Permissions.Commands.{ConsentScope, RemoveScope}

  @doc "Delegates to #{CreateIdentity}.execute/1"
  defdelegate create_identity(input), to: CreateIdentity, as: :execute

  @doc "Delegates to #{GetIdentity}.execute/1"
  defdelegate get_identity(input), to: GetIdentity, as: :execute

  @doc "Delegates to #{ConsentScope}.execute/2"
  defdelegate consent_scope(identity, scopes), to: ConsentScope, as: :execute

  @doc "Delegates to #{RemoveScope}.execute/2"
  defdelegate remove_scope(identity, scopes), to: RemoveScope, as: :execute

  @doc "Delegates to #{PasswordIsAllowed}.execute/1"
  defdelegate password_allowed?(password), to: PasswordIsAllowed, as: :execute
end
