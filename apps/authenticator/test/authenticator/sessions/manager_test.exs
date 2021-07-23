defmodule Authenticator.Sessions.ManagerTest do
  @moduledoc false

  use Authenticator.DataCase, async: true

  alias Authenticator.Sessions.Manager
  alias Authenticator.Sessions.Schemas.Session

  describe "#{Manager}.execute/0" do
    setup do
      {:ok, active_session: insert!(:session, status: "active")}
    end

    test "succeed in updating statuses", ctx do
      session =
        insert!(:session,
          status: "active",
          inserted_at:
            NaiveDateTime.utc_now()
            |> NaiveDateTime.add(-120)
            |> NaiveDateTime.truncate(:second),
          expires_at:
            NaiveDateTime.utc_now()
            |> NaiveDateTime.add(-60)
            |> NaiveDateTime.truncate(:second)
        )

      assert {:ok, :sessions_updated} == Manager.execute()
      assert %Session{status: "expired"} = Repo.get(Session, session.id)
      assert %Session{status: "active"} = Repo.get(Session, ctx.active_session.id)
    end

    test "only updates from active to expired", ctx do
      refreshed_session =
        insert!(:session,
          status: "refreshed",
          inserted_at:
            NaiveDateTime.utc_now()
            |> NaiveDateTime.add(-120)
            |> NaiveDateTime.truncate(:second),
          expires_at:
            NaiveDateTime.utc_now()
            |> NaiveDateTime.add(-60)
            |> NaiveDateTime.truncate(:second)
        )

      invalidated_session =
        insert!(:session,
          status: "invalidated",
          inserted_at:
            NaiveDateTime.utc_now()
            |> NaiveDateTime.add(-120)
            |> NaiveDateTime.truncate(:second),
          expires_at:
            NaiveDateTime.utc_now()
            |> NaiveDateTime.add(-60)
            |> NaiveDateTime.truncate(:second)
        )

      assert {:ok, :sessions_updated} == Manager.execute()
      assert %Session{status: "refreshed"} = Repo.get(Session, refreshed_session.id)
      assert %Session{status: "invalidated"} = Repo.get(Session, invalidated_session.id)
      assert %Session{status: "active"} = Repo.get(Session, ctx.active_session.id)
    end
  end
end
