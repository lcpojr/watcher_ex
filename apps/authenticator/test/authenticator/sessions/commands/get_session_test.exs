defmodule Authenticator.Sessions.Commands.GetSessionTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.Repo
  alias Authenticator.Sessions.Commands.GetSession
  alias Authenticator.Sessions.Commands.Inputs.GetSession, as: Input
  alias Authenticator.Sessions.Schemas.Session

  setup do
    {:ok, session: insert!(:session)}
  end

  describe "#{GetSession}.execute/2" do
    test "succeeds in getting subject session if params are valid", ctx do
      input = %{
        id: ctx.session.id,
        jti: ctx.session.jti,
        subject_id: ctx.session.subject_id,
        subject_type: ctx.session.subject_type,
        status: ctx.session.status
      }

      assert {:ok, %Session{} = user} = GetSession.execute(input)
      assert user == Repo.one(Session)
    end

    test "fails if session does not exist" do
      assert {:error, :not_found} = GetSession.execute(%Input{id: Ecto.UUID.generate()})
    end

    test "fails if parameters are empty" do
      assert {:error, %{errors: [jti: {"All input fields are empty", []}]}} =
               GetSession.execute(%{})
    end
  end
end
