defmodule ResourceManager.Repo.Migrations.CreatePublicKeyTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:public_keys, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :value, :text, null: false
      add :type, :string, null: false, default: "rsa"
      add :format, :string, null: false, default: "pem"

      add :client_application_id, references(:client_applications, type: :uuid), null: false

      timestamps()
    end

    create_if_not_exists unique_index(:public_keys, [:client_application_id])
  end
end
