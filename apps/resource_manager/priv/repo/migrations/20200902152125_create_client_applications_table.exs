defmodule ResourceManager.Repo.Migrations.CreateClientApplicationsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:client_applications, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :client_id, :uuid, null: false
      add :name, :string, null: false
      add :secret, :string, null: false
      add :description, :string, null: true
      add :status, :string, null: false, default: "active"
      add :protocol, :string, null: false, default: "openid-connect"
      add :access_type, :string, null: false, default: "confidential"
      add :is_admin, :boolean, null: false, default: false
      add :grant_flows, {:array, :string}
      add :redirect_uri, :string

      timestamps()
    end

    create_if_not_exists unique_index(:client_applications, [:client_id])
  end
end
