defmodule ResourceManager.Repo.Migrations.AlterApplicationCreateBlockedUntil do
  use Ecto.Migration

  def change do
    alter table(:client_applications) do
      add :blocked_until, :naive_datetime
    end

    create_if_not_exists index(:client_applications, [:client_id, :status, :blocked_until])
  end
end
