defmodule Authenticator.Sessions.Tokens.AccessToken do
  @moduledoc """
  Access token configurations.
  """

  use Joken.Config

  add_hook Joken.Hooks.RequiredClaims, ~w(exp iat nbf iss aud azp jti sub typ scope)
  add_hook Authenticator.Sessions.Tokens.Hooks.ValidateUUID, ~w(sub aud)

  # Two hours in seconds
  @max_exp 60 * 60 * 2

  @default_issuer "WatcherEx"
  @default_type "Bearer"
  @identity_types ~w(user application)

  @impl true
  def token_config do
    [iss: @default_issuer, skip: [:aud, :exp]]
    |> default_claims()
    |> add_claim("aud", & &1, &is_binary/1)
    |> add_claim("ttl", &gen_ttl/0, &is_integer/1)
    |> add_claim("exp", &gen_exp/0, fn exp, _, _ -> is_integer(exp) and valid_expiration?(exp) end)
    |> add_claim("azp", & &1, &is_binary/1)
    |> add_claim("sub", & &1, &is_binary/1)
    |> add_claim("typ", nil, fn value, _, _ -> value == @default_type end)
    |> add_claim("identity", & &1, fn value, _, _ -> value in @identity_types end)
    |> add_claim("scope", nil, &is_binary/1)
  end

  defp gen_ttl, do: @max_exp
  defp gen_exp, do: current_time() + @max_exp
  defp valid_expiration?(exp), do: exp >= current_time() && exp <= current_time() + @max_exp
end
