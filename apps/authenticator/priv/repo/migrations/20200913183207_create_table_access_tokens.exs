defmodule Authenticator.Repo.Migrations.CreateTableAccessTokens do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:access_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :jti, :uuid, null: false
      add :claims, :map, null: false
      add :status, :string, null: false, default: "active"
      add :expires_at, :naive_datetime, null: false
      add :grant_flow, :string, null: false

      timestamps()
    end

    create_if_not_exists unique_index(:access_tokens, [:jti])
  end
end
