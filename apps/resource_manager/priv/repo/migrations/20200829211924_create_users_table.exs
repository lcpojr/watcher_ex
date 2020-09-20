defmodule ResourceManager.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :username, :string, null: false
      add :status, :string, null: false, default: "active"
      add :is_admin, :boolean, null: false, default: false

      timestamps()
    end

    create_if_not_exists unique_index(:users, [:username, :status])
  end
end
