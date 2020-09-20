defmodule RestApi.ErrorViewTest do
  use RestApi.ConnCase, async: true

  import Phoenix.View

  test "renders 404.json" do
    assert render(RestApi.ErrorView, "404.json", []) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500.json" do
    assert render(RestApi.ErrorView, "500.json", []) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
