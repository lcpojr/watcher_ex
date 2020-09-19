defmodule Authenticator.Sessions do
  @moduledoc false

  use Authenticator.Domain, schema_model: Authenticator.Sessions.Schemas.Session

  @doc "Converts an expiration to a NaiveDateTime"
  @spec convert_expiration(expiration :: integer()) :: NaiveDateTime.t()
  def convert_expiration(expiration) do
    expiration
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_naive()
  end
end
