defmodule Authenticator.Sessions.Tokens.AccessToken do
  @moduledoc """
  Access token configurations.
  """

  use Joken.Config

  add_hook Joken.Hooks.RequiredClaims, ~w(exp iat nbf iss aud azp jti sub typ scope)
  add_hook Authenticator.Sessions.Tokens.Hooks.ValidateUUID, ~w(sub aud)

  @default_issuer "WatcherEx"
  @default_type "Bearer"

  @impl true
  def token_config do
    [iss: @default_issuer, skip: [:aud]]
    |> default_claims()
    |> add_claim("aud", & &1, &is_binary/1)
    |> add_claim("azp", & &1, &is_binary/1)
    |> add_claim("sub", & &1, &is_binary/1)
    |> add_claim("typ", nil, fn value, _, _ -> value == @default_type end)
    |> add_claim("scope", nil, &is_binary/1)
  end
end
