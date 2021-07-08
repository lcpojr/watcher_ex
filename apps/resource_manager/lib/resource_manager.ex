defmodule ResourceManager do
  @moduledoc """
  Application to deal with request's to the resource server.
  """

  alias ResourceManager.Credentials.Commands.PasswordIsAllowed
  alias ResourceManager.Credentials.TOTPs
  alias ResourceManager.Identities.Commands.{CreateClientApplication, CreateUser, GetIdentity}
  alias ResourceManager.Permissions.Commands.{ConsentScope, RemoveScope}

  @doc "Delegates to #{CreateUser}.execute/1"
  defdelegate create_user(input), to: CreateUser, as: :execute

  @doc "Delegates to #{CreateClientApplication}.execute/1"
  defdelegate create_client_application(input), to: CreateClientApplication, as: :execute

  @doc "Delegates to #{GetIdentity}.execute/1"
  defdelegate get_identity(input), to: GetIdentity, as: :execute

  @doc "Delegates to #{ConsentScope}.execute/2"
  defdelegate consent_scope(identity, scopes), to: ConsentScope, as: :execute

  @doc "Delegates to #{RemoveScope}.execute/2"
  defdelegate remove_scope(identity, scopes), to: RemoveScope, as: :execute

  @doc "Delegates to #{PasswordIsAllowed}.execute/1"
  defdelegate password_allowed?(password), to: PasswordIsAllowed, as: :execute

  @doc "Delegates to #{TOTP}.valid_code?/2"
  defdelegate valid_totp?(totp, code), to: TOTPs, as: :valid_code?
end
