defmodule Authenticator do
  @moduledoc """
  Application to deal with request's to authenticator server.
  """

  alias Authenticator.Crypto.Commands.{FakeVerifyHash, GenerateHash, VerifyHash}
  alias Authenticator.Sessions.Tokens.AccessToken
  alias Authenticator.Sessions.Commands.{GetSession, LogoutAllSessions, LogoutSession}
  alias Authenticator.SignIn.Commands.{RefreshToken, ResourceOwner}

  @doc "Delegates to #{ResourceOwner}.execute/1"
  defdelegate sign_in_resource_owner(input), to: ResourceOwner, as: :execute

  @doc "Delegates to #{RefreshToken}.execute/1"
  defdelegate sign_in_refresh_token(input), to: RefreshToken, as: :execute

  @doc "Delegates to #{GetSession}.execute/1"
  defdelegate get_session(input), to: GetSession, as: :execute

  @doc "Delegates to #{LogoutSession}.execute/1"
  defdelegate logout_session(session), to: LogoutSession, as: :execute

  @doc "Delegates to #{LogoutAllSessions}.execute/2"
  defdelegate logout_all_sessions(subject_id, subject_type), to: LogoutAllSessions, as: :execute

  @doc "Delegates to #{FakeVerifyHash}.execute/1"
  defdelegate fake_verify_hash(algorithm), to: FakeVerifyHash, as: :execute

  @doc "Delegates to #{GenerateHash}.execute/2"
  defdelegate generate_hash(value, algorithm), to: GenerateHash, as: :execute

  @doc "Delegates to #{VerifyHash}.execute/2"
  defdelegate verify_hash(identity, hash), to: VerifyHash, as: :execute

  @doc "Delegates to #{VerifyHash}.execute/3"
  defdelegate verify_hash(value, hash, algorithm), to: VerifyHash, as: :execute

  @doc "Delegates to #{AccessToken}.verify_and_validate/1"
  defdelegate validate_access_token(token), to: AccessToken, as: :verify_and_validate
end
