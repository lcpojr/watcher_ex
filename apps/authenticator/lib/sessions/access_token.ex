defmodule Authenticator.Sessions.AccessToken do
  use Joken.Config

  add_hook(Joken.Hooks.RequiredClaims, ensure: ~w(exp iat nbf iss aud jti sub typ scope))

  @default_issuer "WatcherEx"
  @default_type "Bearer"

  @impl true
  def token_config do
    [iss: @default_issuer, skip: [:aud]]
    |> default_claims()
    |> add_claim("aud", & &1, fn value, _, ctx -> value == ctx.audience end)
    |> add_claim("sub", & &1, fn value, _, ctx -> value == ctx.subject end)
    |> add_claim("typ", nil, fn value, _, _ -> value == @default_type end)
    |> add_claim("scope", nil, &is_binary/1)
  end
end
