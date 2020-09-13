defmodule Authenticator.Sessions.Tokens.RefreshToken do
  @moduledoc """
  Refresh token configurations.
  """

  use Joken.Config

  add_hook Joken.Hooks.RequiredClaims, ~w(exp iat nbf iss aud jti typ)

  # One month in seconds
  @max_expiration 30 * (24 * (60 * 60))
  @default_issuer "WatcherEx"
  @default_type "Bearer"

  @impl true
  def token_config do
    [iss: @default_issuer, skip: [:aud, :exp]]
    |> default_claims()
    |> add_claim("aud", & &1, &is_binary/1)
    |> add_claim("sub", & &1, &is_binary/1)
    |> add_claim("exp", &gen_exp/0, fn exp, _, _ -> is_integer(exp) and valid_expiration?(exp) end)
    |> add_claim("typ", nil, fn type, _, _ -> type == @default_type end)
  end

  defp gen_exp, do: Joken.current_time() + @max_expiration
  defp valid_expiration?(exp), do: exp >= timestamp() && exp <= timestamp() + @max_expiration
  defp timestamp, do: Joken.current_time()
end
