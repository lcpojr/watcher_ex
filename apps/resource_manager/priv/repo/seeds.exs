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

  public_key = """
  -----BEGIN PUBLIC KEY-----
  MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAp/1foh6lAeJS9EYgJxQ/
  zWu2k919+t0gqqbvelW+QMHnir7CMSB94ivDW9ITvQKp9ETmrXhkAF+ht2Ye86j3
  hgWSZ633qFfKFvBbeY3xWR5dVYVBNCJJuNTlij33Jj6WtzPnEtBe1amPxf1s+t2/
  08PqzOR2qQh53HWIw+uvRd4UU3oNuCjSw7E12fgcO1b6A6stKRZ4kP1pZpyL2gII
  RgUz3desmnAzMOL4mBYGto31aenDcTx6vvaGj5QlTH1iQ8vQQV2n5sBGynLVkZ1W
  acy1uoq4L+Nwr3wXS2mRDE8MoF/R5V1oAyupJFIWNkHvZ0AlVTY+t8ytA0Ki+dRQ
  Zizd5EiCtj7hiVOP7ZhaPOHsZnpbsRHgcjrFzI6unb7rigWun9r2b4x/guQ4Ow8Q
  UkusVn9CWU/td1psGlNaBjjG9Db5JmX2ADnHzRDgVw9BzAV8qi930rv8i+WO3mlv
  fH9ujDgOL/Tcs8/VxyTk8SdSwGFS89xN71AL/qIz4y1enuvzKzhqJB6To3wOZoFq
  sHa16A5R+QhGvC51mTW+0LuFwvEKBYyv/8DfOERmM5tNVmfjZapUbnRVbTFfymxk
  HKdl9Lb/NVYqKoxZfk6Ic0abjDyBjlBLM3wyq8NETytbKwxoCOcxDv2FnE6HB6nH
  btt2ARmB2btMAD94GmGVG2ECAwEAAQ==
  -----END PUBLIC KEY-----
  """

  Repo.insert!(%PublicKey{client_application: app, value: public_key})
end)
