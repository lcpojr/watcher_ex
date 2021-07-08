# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias ResourceManager.Credentials.Schemas.{Password, PublicKey}
alias ResourceManager.Identities.Schemas.{ClientApplication, User}
alias ResourceManager.Permissions.Schemas.{ClientApplicationScope, Scope, UserScope}
alias ResourceManager.Repo

Repo.transaction(fn ->
  now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  scope_read = Repo.insert!(%Scope{name: "admin:read", description: "Can read all admin data"})
  scope_write = Repo.insert!(%Scope{name: "admin:write", description: "Can edit all admin data"})

  user = Repo.insert!(%User{username: "admin", status: "active", is_admin: true})
  Repo.insert!(%Password{user: user, password_hash: Argon2.hash_pwd_salt("admin")})
  Repo.insert!(%UserScope{user: user, scope: scope_read, inserted_at: now, updated_at: now})
  Repo.insert!(%UserScope{user: user, scope: scope_write, inserted_at: now, updated_at: now})

  app =
    Repo.insert!(%ClientApplication{
      name: "admin",
      description: "Admin test application",
      status: "active",
      grant_flows: ["resource_owner", "refresh_token", "client_credentials"],
      secret: Bcrypt.hash_pwd_salt("my-secret")
    })

  Repo.insert!(%ClientApplicationScope{
    client_application: app,
    scope: scope_read,
    inserted_at: now,
    updated_at: now
  })

  Repo.insert!(%ClientApplicationScope{
    client_application: app,
    scope: scope_write,
    inserted_at: now,
    updated_at: now
  })

  public_key =
    :resource_manager
    |> :code.priv_dir()
    |> Path.join("/keys/resource_manager_key.pub")
    |> File.read!()

  Repo.insert!(%PublicKey{client_application: app, value: public_key})
end)
