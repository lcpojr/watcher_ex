defmodule ResourceManager do
  @moduledoc """
  Resource manager is an application to deal's with request's to
  resource server.
  """

  alias ResourceManager.Commands.{CreateIdentity, ConsentScope, RemoveScope}

  @doc "Delegates to #{CreateIdentity}/1"
  defdelegate create_identity(input), to: CreateIdentity, as: :execute

  @doc "Delegates to #{ConsentScope}/2"
  defdelegate consent_scope(identity, scopes), to: ConsentScope, as: :execute

  @doc "Delegates to #{RemoveScope}/2"
  defdelegate remove_scope(identity, scopes), to: RemoveScope, as: :execute
end
