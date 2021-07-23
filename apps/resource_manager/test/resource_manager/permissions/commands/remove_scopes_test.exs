defmodule ResourceManager.Permissions.Commands.RemoveScopeTest do
  @moduledoc false

  use ResourceManager.DataCase, async: true

  alias ResourceManager.Permissions.Commands.RemoveScope
  alias ResourceManager.Permissions.Schemas.{ClientApplicationScope, UserScope}
  alias ResourceManager.Repo

  setup do
    user = insert!(:user)
    application = insert!(:client_application)
    scopes = insert_list!(:scope)

    {:ok, user: user, application: application, scopes: scopes}
  end

  describe "#{RemoveScope}.execute/2" do
    setup ctx do
      {:ok, params: Enum.map(ctx.scopes, & &1.id)}
    end

    test "succeeds in removing from user if params are valid", ctx do
      Enum.map(ctx.scopes, &insert!(:user_scope, user: ctx.user, scope: &1))
      assert :ok = RemoveScope.execute(ctx.user, ctx.params)
      assert [] == Repo.all(UserScope)
    end

    test "succeeds in removing from client application if params are valid", ctx do
      Enum.map(
        ctx.scopes,
        &insert!(:client_application_scope, client_application: ctx.application, scope: &1)
      )

      assert :ok = RemoveScope.execute(ctx.application, ctx.params)
      assert [] == Repo.all(ClientApplicationScope)
    end

    test "succeeds even if scopes not found on user", ctx do
      assert :ok = RemoveScope.execute(ctx.user, ctx.params)
      assert [] == Repo.all(UserScope)
    end

    test "succeeds even if scopes not found on client application", ctx do
      assert :ok = RemoveScope.execute(ctx.application, ctx.params)
      assert [] == Repo.all(UserScope)
    end
  end
end
