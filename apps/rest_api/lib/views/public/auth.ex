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
end
