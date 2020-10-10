defmodule Authenticator.SignIn.ApplicationAttempts do
  @moduledoc """
  A application attemp is a representation of an valid or not sign in attempt by the application;

  This is used in order to check if the application should be temporarilly blocked or not.
  """

  use Authenticator.Domain, schema_model: Authenticator.SignIn.Schemas.ApplicationAttempt
end
