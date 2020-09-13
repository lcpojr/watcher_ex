defmodule Authenticator.Repo do
  @moduledoc false

  use Ecto.Repo, otp_app: :authenticator, adapter: Ecto.Adapters.Postgres
end
