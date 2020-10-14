defmodule ResourceManager.Identities.Users do
  @moduledoc """
  Users are subject identities that are impersonates by a person.

  An user is allowed to do certain actions by authenticating in the authentication
  provider with success.

  What a user can do is defined by it's scopes.
  """

  use ResourceManager.Domain, schema_model: ResourceManager.Identities.Schemas.User
end
