defmodule RestAPI.RestAPI.Views.Errors.DefaultTest do
  use RestAPI.ConnCase, async: true

  import Phoenix.View

  alias RestAPI.Views.Errors.Default

  test "renders 401.json" do
    assert %{
             status: 401,
             error: "unauthorized",
             detail: "Not authorized to perform such action"
           } == render(Default, "401.json", [])
  end

  test "renders 403.json" do
    assert %{
             status: 403,
             error: "unauthenticated",
             detail: "Not authenticated so cannot due such action"
           } == render(Default, "403.json", [])
  end

  test "renders 404.json" do
    assert %{
             status: 404,
             error: "not_found",
             detail: "Endpoint not found"
           } == render(Default, "404.json", [])
  end

  test "renders 500.json" do
    assert %{
             status: 500,
             error: "internal_server_error",
             detail: "Internal Server Error"
           } == render(Default, "500.json", [])
  end

  test "renders when template not found" do
    assert %{
             status: 501,
             error: "not_implemented",
             detail: "Endpoint not implemented"
           } == Default.template_not_found("501.json", [])
  end
end
