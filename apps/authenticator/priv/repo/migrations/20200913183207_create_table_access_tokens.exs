defmodule Authenticator.Repo.Migrations.CreateTableSessions do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:sessions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :jti, :string, null: false
      add :subject_id, :string, null: false
      add :subject_type, :string, null: false
      add :claims, :map, null: false
      add :status, :string, null: false, default: "active"
      add :expires_at, :naive_datetime, null: false
      add :grant_flow, :string, null: false

      timestamps()
    end

    create_if_not_exists unique_index(:sessions, [:jti])
    create_if_not_exists index(:sessions, [:subject_id, :subject_type, :status])
    create_if_not_exists index(:sessions, [:status, :inserted_at, :expires_at])
  end
end
