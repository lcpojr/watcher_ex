defmodule RestAPI.Views.Errors.Default do
  @moduledoc false

  use RestAPI.View

  def render("401.json", _assigns) do
    %{
      status: 401,
      error: "unauthorized",
      detail: "Not authorized to perform such action"
    }
  end

  def render("403.json", _assigns) do
    %{
      status: 403,
      error: "unauthenticated",
      detail: "Not authenticated so cannot due such action"
    }
  end

  def render("404.json", _assigns) do
    %{
      status: 404,
      error: "not_found",
      detail: "Endpoint not found"
    }
  end

  def render("500.json", _assigns) do
    %{
      status: 500,
      error: "internal_server_error",
      detail: "Internal Server Error"
    }
  end

  def template_not_found(_template, _assigns) do
    %{
      status: 501,
      error: "not_implemented",
      detail: "Endpoint not implemented"
    }
  end
end
