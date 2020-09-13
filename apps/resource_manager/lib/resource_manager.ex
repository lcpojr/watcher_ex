defmodule ResourceManager do
  @moduledoc """
  Application to deal's with request's to the resource server.
  """

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
end
