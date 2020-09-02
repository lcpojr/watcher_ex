defmodule ResourceManager.Repo.Migrations.CreatePasswordsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:passwords, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :password_hash, :string, null: false
      add :algorithm, :string, null: false, default: "argon2"

      add :user_id, references(:users, type: :uuid), null: false

      timestamps()
    end

    create_if_not_exists unique_index(:passwords, [:user_id])
  end
end
