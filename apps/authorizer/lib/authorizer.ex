defmodule Authorizer do
  @moduledoc """
  Application to deal with request's to authorization server.
  """

  alias Authorizer.Rules.Commands.{AdminAccess, AuthorizationCodeSignIn, PublicAccess}

  @doc "Delegates to #{AdminAccess}.execute/1"
  defdelegate authorize_admin(conn), to: AdminAccess, as: :execute

  @doc "Delegates to #{PublicAccess}.execute/1"
  defdelegate authorize_public(conn), to: PublicAccess, as: :execute

  @doc "Delegates to #{AuthorizationCodeSignIn}.execute/1"
  defdelegate authorize_authorization_code_sign_in(input, user_id),
    to: AuthorizationCodeSignIn,
    as: :execute
end
