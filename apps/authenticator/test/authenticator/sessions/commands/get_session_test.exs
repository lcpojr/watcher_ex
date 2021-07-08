defmodule Authenticator.Sessions.Commands.GetSessionTest do
  use Authenticator.DataCase, async: true

  import ExUnit.CaptureLog

  alias Authenticator.Repo
  alias Authenticator.Sessions.Cache
  alias Authenticator.Sessions.Commands.GetSession
  alias Authenticator.Sessions.Commands.Inputs.GetSession, as: Input
  alias Authenticator.Sessions.Schemas.Session

  setup do
    current_level = Logger.level()
    Logger.configure(level: :info)
    on_exit(fn ->
      Logger.configure(level: current_level)
      Cache.flush()
    end)

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

      assert capture_log(fn ->
        assert {:ok, %Session{} = session} = GetSession.execute(input)
        assert session == Repo.one(Session)
      end) =~ "Session not found on cache"


    end

    test "succeeds gettin subject session from cache if it exists", ctx do
      Cache.set(ctx.session.jti, ctx.session)

      input = %{
        id: ctx.session.id,
        jti: ctx.session.jti,
        subject_id: ctx.session.subject_id,
        subject_type: ctx.session.subject_type,
        status: ctx.session.status
      }

      assert capture_log(fn ->
        assert {:ok, %Session{} = session} = GetSession.execute(input)
        assert session == Repo.one(Session)
      end) =~ "Session #{ctx.session.id} found on cache"
    end

    test "fails if session does not exist" do
      assert {:error, :not_found} = GetSession.execute(%Input{id: Ecto.UUID.generate()})
    end

    test "fails if parameters are empty" do
      assert {:error, changeset} = GetSession.execute(%{})
      assert %{jti: ["All input fields are empty"]} = errors_on(changeset)
    end
  end
end
