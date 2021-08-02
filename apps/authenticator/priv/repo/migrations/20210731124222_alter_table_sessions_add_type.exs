defmodule Authenticator.Repo.Migrations.AlterTableSessionsAddType do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :type, :string, null: false
    end

    create_if_not_exists index(:sessions, [:jti, :type])
  end
end
