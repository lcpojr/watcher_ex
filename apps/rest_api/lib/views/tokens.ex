defmodule RestAPI.Views.Tokens do
  @moduledoc false

  use RestAPI.View

  def render("sign_in.json", %{response: response}) do
    %{
      access_token: response.access_token,
      refresh_token: response.refresh_token,
      expires_at: response.expires_at,
      scope: response.scope
    }
  end
end
