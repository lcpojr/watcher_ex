defmodule Authenticator.Repo.Migrations.CreateUserSignInAttemptTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:user_sign_in_attempt, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :username, :string, null: false
      add :was_successful, :boolean, null: false
      add :ip_address, :string, null: false

      timestamps()
    end

    create_if_not_exists index(:user_sign_in_attempt, [:username, :was_successful, :ip_address])
  end
end
