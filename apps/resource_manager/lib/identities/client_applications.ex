defmodule ResourceManager.Identities.ClientApplications do
  @moduledoc """
  Client application are subject identities that are not impersonated by a person.

  A client application is allowed to do certain actions by authenticating in the authentication
  provider with success.

  What a client application can do is defined by it's scopes.
  """

  use ResourceManager.Domain, schema_model: ResourceManager.Identities.Schemas.ClientApplication
end
