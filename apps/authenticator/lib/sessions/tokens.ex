defmodule Authenticatior.Sessions.Tokens do
  @moduledoc false

  alias Authenticator.Sessions.AccessToken
  alias ResourceManager.Identity.Schemas.{ClientApplication, User}

  @doc "Generates a access token for the given user"
  @spec generate_access_token(app :: ClientApplication.t(), user :: User.t()) :: {:ok, String.t()}
  def generate_access_token(
        %ClientApplication{scopes: [_ | _]} = application,
        %User{scopes: [_ | _]} = user,
        type \\ "Bearer"
      ) do
    %{
      "aud" => application.id,
      "sub" => user.id,
      "typ" => type,
      "scopes" => ["scope"]
    }
    |> AccessToken.generate_and_sign()
    |> case do
      {:ok, access_token, _claims} -> {:ok, access_token}
      error -> error
    end
  end
end
