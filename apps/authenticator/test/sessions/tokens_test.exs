defmodule Authenticator.Sessions.TokensTest do
  use ResourceManager.DataCase, async: true

  alias Authenticatior.Sessions.Tokens

  setup do
    user = insert!(:user)
    app = insert!(:client_application)
    scopes = insert_list!(:scope)

    Enum.map(scopes, &insert!(:user_scope, user: user, scope: &1))
    Enum.map(scopes, &insert!(:client_application_scope, client_application: app, scope: &1))

    {:ok, user: Repo.preload(user, :scopes), application: Repo.preload(app, :scopes)}
  end

  describe "#{Tokens}.generate_access_token/2" do
    test "succeeds if user and application are valid", ctx do
      assert access_token = Tokens.generate_access_token(ctx.application, ctx.user)
      assert is_binary(access_token)
    end
  end
end
