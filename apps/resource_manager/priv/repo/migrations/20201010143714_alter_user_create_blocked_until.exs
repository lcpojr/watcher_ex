defmodule ResourceManager.Repo.Migrations.AlterUserCreateBlockedUntil do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :blocked_until, :naive_datetime
    end

    drop_if_exists index(:users, [:username, :status])
    create_if_not_exists unique_index(:users, [:username])
    create_if_not_exists index(:users, [:username, :status, :blocked_until])
  end
end
