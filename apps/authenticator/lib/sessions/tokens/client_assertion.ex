defmodule Authenticator.Sessions.Tokens.ClientAssertion do
  @moduledoc """
  Client assertion token configurations.
  """

  use Joken.Config

  add_hook Joken.Hooks.RequiredClaims, ~w(exp iat nbf iss aud jti sub typ)
  add_hook Authenticator.Sessions.Tokens.Hooks.ValidateUUID, ~w(sub aud)
  add_hook Authenticator.Sessions.Tokens.Hooks.ValidateEqualty, ~w(sub iss)

  # Two hours in seconds
  @max_exp 60 * 60 * 2

  @default_issuer "WatcherEx"
  @default_type "Bearer"

  @impl true
  def token_config do
    [iss: @default_issuer, skip: [:aud, :exp]]
    |> default_claims()
    |> add_claim("aud", & &1, &is_binary/1)
    |> add_claim("exp", &gen_exp/0, fn exp, _, _ -> is_integer(exp) and valid_expiration?(exp) end)
    |> add_claim("sub", & &1, fn value, _, ctx -> value == ctx.client_id end)
    |> add_claim("typ", nil, fn value, _, _ -> value == @default_type end)
  end

  defp gen_exp, do: current_time() + @max_exp
  defp valid_expiration?(exp), do: exp >= current_time() && exp <= current_time() + @max_exp
end
