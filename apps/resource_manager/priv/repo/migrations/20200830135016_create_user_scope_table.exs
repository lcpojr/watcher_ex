defmodule ResourceManager.Repo.Migrations.CreateUserScopeTable do
  use Ecto.Migration

  @unique_index_fields [:user_id, :scope_id]

  def change do
    create_if_not_exists table(:users_scopes, primary_key: false) do
      add :user_id, references(:users, type: :uuid), null: false, primary_key: true
      add :scope_id, references(:scopes, type: :uuid), null: false, primary_key: true

      timestamps()
    end

    create_if_not_exists unique_index(:users_scopes, @unique_index_fields)
  end
end
