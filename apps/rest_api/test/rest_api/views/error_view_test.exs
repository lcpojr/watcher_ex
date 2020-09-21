defmodule RestAPI.ErrorViewTest do
  use RestAPI.ConnCase, async: true

  import Phoenix.View

  alias RestAPI.ErrorView

  test "renders 404.json" do
    assert render(ErrorView, "404.json", []) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500.json" do
    assert render(ErrorView, "500.json", []) == %{errors: %{detail: "Internal Server Error"}}
  end
end
