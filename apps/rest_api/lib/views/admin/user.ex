defmodule RestAPI.Views.Admin.User do
  @moduledoc false

  use RestAPI.View

  def render("create.json", %{response: response}) do
    %{
      id: response.id,
      username: response.username,
      status: response.status,
      is_admin: response.is_admin,
      inserted_at: response.inserted_at,
      update_at: response.updated_at
    }
  end

  def render("show.json", %{response: response}) do
    %{
      id: response.id,
      username: response.username,
      status: response.status,
      is_admin: response.is_admin,
      inserted_at: response.inserted_at,
      updated_at: response.updated_at
    }
  end
end
