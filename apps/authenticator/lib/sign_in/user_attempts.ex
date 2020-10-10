defmodule Authenticator.SignIn.UserAttempts do
  @moduledoc """
  A user attemp is a representation of an valid or not sign in attempt by the user;

  This is used in order to check if the user should be temporarilly blocked or not.
  """

  use Authenticator.Domain, schema_model: Authenticator.SignIn.Schemas.UserAttempt
end
