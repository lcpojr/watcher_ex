defmodule ResourceManager.Repo.Migrations.CreateTableTotps do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:totps, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :secret, :string, null: false
      add :digits, :integer, null: false, default: 6
      add :period, :integer, null: false, default: 60
      add :issuer, :string, null: false, default: "WatcherEx"

      add :user_id, references(:users, type: :uuid), null: false

      timestamps()
    end

    create_if_not_exists unique_index(:totps, [:user_id])
  end
end
