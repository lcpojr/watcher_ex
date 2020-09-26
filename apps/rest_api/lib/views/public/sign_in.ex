defmodule RestAPI.Views.Public.SignIn do
  @moduledoc false

  use RestAPI.View

  def render("sign_in.json", %{response: response}) do
    %{
      access_token: response.access_token,
      refresh_token: response.refresh_token,
      expires_in: response.expires_in,
      token_type: response.token_type
    }
  end
end
