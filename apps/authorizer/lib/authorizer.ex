defmodule Authorizer do
  @moduledoc """
  Application to deal with request's to authorization server.
  """

  alias Authorizer.Rules.Commands.AdminAccess

  @doc "Delegates to #{AdminAccess}.execute/1"
  defdelegate authorize_admin(conn), to: AdminAccess, as: :execute
end
