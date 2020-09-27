defmodule Authenticator.Sessions.Tokens.ClientAssertion do
  @moduledoc """
  Client assertion token configurations.
  """

  use Joken.Config

  add_hook Joken.Hooks.RequiredClaims, ~w(exp iat nbf iss aud jti typ)
  add_hook Authenticator.Sessions.Tokens.Hooks.ValidateUUID, ~w(iss)

  # Two hours in seconds
  @max_exp 60 * 60 * 2

  @default_audience "WatcherEx"
  @default_type "Bearer"

  @impl true
  def token_config do
    [skip: [:iss, :aud, :exp]]
    |> default_claims()
    |> add_claim("iss", & &1, fn value, _, ctx -> value == ctx.client_id end)
    |> add_claim("aud", & &1, fn value, _, _ -> value == @default_audience end)
    |> add_claim("exp", &gen_exp/0, fn exp, _, _ -> is_integer(exp) and valid_expiration?(exp) end)
    |> add_claim("typ", nil, fn value, _, _ -> value == @default_type end)
  end

  defp gen_exp, do: current_time() + @max_exp
  defp valid_expiration?(exp), do: exp >= current_time() && exp <= current_time() + @max_exp
end
