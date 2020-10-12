defmodule Authorizer.Policies.Behaviour do
  @moduledoc """
  A policy is a set of verifications to make sure that a subject can do such action.
  """

  @doc "Return the policy description"
  @callback info() :: String.t()

  @doc "Runs the input validations"
  @callback validate(conn :: Plug.Conn.t()) :: {:ok, context :: map()} | {:error, atom()}

  @doc "Runs the authorization policy"
  @callback execute(context :: map(), opts :: Keyword.t()) :: :ok | {:error, :unauthorized}
end
