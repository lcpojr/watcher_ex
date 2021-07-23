defmodule Authenticator.SignIn.Commands.SignOutSessionTest do
  @moduledoc false

  use Authenticator.DataCase, async: true

  alias Authenticator.SignOut.Commands.SignOutSession, as: Commands

  describe "#{Commands}.execute/1" do
    test "succeeds if session is valid" do
      session = insert!(:session)
      assert {:ok, %{id: id, status: "invalidated"}} = Commands.execute(session)
      assert session.id == id
    end

    test "succeeds if valid jti was passed and session active" do
      session = insert!(:session)
      assert {:ok, %{id: id, status: "invalidated"}} = Commands.execute(session.jti)
      assert session.id == id
    end

    test "fails if session not active" do
      session = insert!(:session, status: "invalidated")
      assert {:error, :not_active} == Commands.execute(session.jti)
    end

    test "fails if session not found" do
      assert {:error, :not_found} == Commands.execute(Ecto.UUID.generate())
    end

    test "fails if params are invalid" do
      assert {:error, :invalid_params} == Commands.execute(nil)
    end
  end
end
