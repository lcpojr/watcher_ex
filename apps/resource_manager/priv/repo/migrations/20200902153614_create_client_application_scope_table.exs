defmodule ResourceManager.Repo.Migrations.CreateClientApplicationScopeTable do
  use Ecto.Migration

  @unique_index_fields [:client_application_id, :scope_id]

  def change do
    create_if_not_exists table(:client_applications_scopes, primary_key: false) do
      add :client_application_id, references(:client_applications, type: :uuid), null: false, primary_key: true
      add :scope_id, references(:scopes, type: :uuid), null: false, primary_key: true

      timestamps()
    end

    create_if_not_exists unique_index(:client_applications_scopes, @unique_index_fields)
  end
end
