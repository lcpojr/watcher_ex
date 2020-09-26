defmodule RestAPI.Plugs.AuthenticationTest do
  use RestAPI.ConnCase, async: true

  alias RestAPI.Plugs.Authentication

  describe "#{Authentication}.init/1" do
    test "returns the given options" do
      assert 1 == Authentication.init(%Plug.Conn{})
    end
  end
end
