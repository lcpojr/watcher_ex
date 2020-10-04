defmodule Authenticator.Repo.Migrations.CreateApplicationSignInAttemptTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:application_sign_in_attempt, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :client_id, :string, null: false
      add :was_successful, :boolean, null: false
      add :ip_address, :string, null: false

      timestamps()
    end

    create_if_not_exists index(:application_sign_in_attempt, [:client_id, :was_successful, :ip_address])
  end
end
