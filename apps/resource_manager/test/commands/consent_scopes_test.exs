defmodule ResourceManager.Commands.ConsentScopeTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Commands.ConsentScope
  alias ResourceManager.Permissions.Schemas.{ClientApplicationScope, UserScope}
  alias ResourceManager.Repo

  setup do
    user = insert!(:user)
    application = insert!(:client_application)
    scopes = insert_list!(:scope)

    {:ok, user: user, application: application, scopes: scopes}
  end

  describe "#{ConsentScope}.execute/2" do
    setup ctx do
      {:ok, params: Enum.map(ctx.scopes, & &1.id)}
    end

    test "succeeds in consenting for user if params are valid", ctx do
      assert {:ok, [%UserScope{} | _] = user_scopes} = ConsentScope.execute(ctx.user, ctx.params)
      assert user_scopes == Repo.all(UserScope)
    end

    test "succeeds in consenting for client application if params are valid", ctx do
      assert {:ok, [%ClientApplicationScope{} | _] = app_scopes} =
               ConsentScope.execute(ctx.application, ctx.params)

      assert app_scopes == Repo.all(ClientApplicationScope)
    end

    test "overwrites if consent already granted to user", ctx do
      Enum.map(ctx.scopes, &insert!(:user_scope, user: ctx.user, scope: &1))
      assert {:ok, [%UserScope{} | _] = user_scopes} = ConsentScope.execute(ctx.user, ctx.params)
      assert user_scopes == Repo.all(UserScope)
    end

    test "overwrites if consent already granted to client application", ctx do
      Enum.map(
        ctx.scopes,
        &insert!(:client_application_scope, client_application: ctx.application, scope: &1)
      )

      assert {:ok, [%ClientApplicationScope{} | _] = client_application_scopes} =
               ConsentScope.execute(ctx.application, ctx.params)

      assert client_application_scopes == Repo.all(ClientApplicationScope)
    end
  end
end
