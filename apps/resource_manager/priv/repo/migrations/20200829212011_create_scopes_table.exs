defmodule ResourceManager.Repo.Migrations.CreateScopesTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:scopes, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text

      timestamps()
    end

    create_if_not_exists unique_index(:scopes, [:name])
  end
end
