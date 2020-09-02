defmodule ResourceManager.Repo do
  @moduledoc false

  use Ecto.Repo, otp_app: :resource_manager, adapter: Ecto.Adapters.Postgres
end
