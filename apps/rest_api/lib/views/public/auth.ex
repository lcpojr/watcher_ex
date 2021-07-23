defmodule RestAPI.Views.Public.Auth do
  @moduledoc false

  use RestAPI.View

  def render("token.json", %{response: response}) do
    %{
      access_token: response.access_token,
      refresh_token: response.refresh_token,
      expires_in: response.expires_in,
      token_type: response.token_type
    }
  end

  def render("authorize.json", %{response: response, state: state}) do
    %{
      code: response.authorization_code,
      state: state
    }
  end
end
