# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias ResourceManager.Factory

user = Factory.insert!(:user, username: "admin", status: "active", is_admin: true)

Factory.insert!(:password,
  user: user,
  password_hash: Factory.gen_hashed_password("admin", :argon2)
)

app =
  Factory.insert!(:client_application,
    name: "admin",
    description: "Admin test application",
    status: "active",
    grant_flows: ["resource_owner", "refresh_token"],
    secret: Factory.gen_hashed_password("my-secret", :bcrypt)
  )

Factory.insert!(:public_key,
  client_application: app,
  value: Factory.get_priv_public_key()
})
