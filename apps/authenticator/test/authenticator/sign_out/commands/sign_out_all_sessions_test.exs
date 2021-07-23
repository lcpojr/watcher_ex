defmodule Authenticator.SignIn.Commands.SignOutAllSessionsTest do
  @moduledoc false

  use Authenticator.DataCase, async: true

  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.SignOut.Commands.SignOutAllSessions, as: Commands

  describe "#{Commands}.execute/1" do
    test "succeeds if session is valid" do
      session = insert!(:session)
      assert {:ok, 1} == Commands.execute(session.subject_id, session.subject_type)
      assert %{status: "invalidated"} = Repo.get_by(Session, id: session.id)
    end

    test "fails if not found any active session" do
      assert {:error, :not_active} == Commands.execute(Ecto.UUID.generate(), "user")
    end

    test "fails if params are invalid" do
      assert {:error, :invalid_params} == Commands.execute(nil, nil)
    end
  end
end
