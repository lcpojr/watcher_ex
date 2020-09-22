defmodule RestAPI.RestAPI.Views.Errors.DefaultTest do
  use RestAPI.ConnCase, async: true

  import Phoenix.View

  alias RestAPI.RestAPI.Views.Errors.Default

  test "renders 404.json" do
    assert render(Default, "404.json", []) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500.json" do
    assert render(Default, "500.json", []) == %{errors: %{detail: "Internal Server Error"}}
  end
end
