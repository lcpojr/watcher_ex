defmodule Authenticator.Sessions do
  @moduledoc """
  An sesssion is a representation of an succeded authentication by a subject.

  The session in this application stores most of the info needed to check if
  an access_token still active or not. This can be done by checking two infos:
    - The Session status has to be `active`;
    - The session expiration cannot be higher than actual date (UTC);
  """

  use Authenticator.Domain, schema_model: Authenticator.Sessions.Schemas.Session

  @doc "Converts an expiration to a NaiveDateTime"
  @spec convert_expiration(expiration :: integer()) :: NaiveDateTime.t()
  def convert_expiration(expiration) when is_integer(expiration) do
    expiration
    |> DateTime.from_unix!(:second)
    |> DateTime.to_naive()
  end
end
