defmodule ResourceManager.Credentials.Passwords do
  @moduledoc """
  Passwords are a type of credential used by a subject in authentication requests.

  It's generally used by users in order to provide an minimum way to ensure
  that a it is who he claim to be when making requests.
  """

  use ResourceManager.Domain, schema_model: ResourceManager.Credentials.Schemas.Password
end
