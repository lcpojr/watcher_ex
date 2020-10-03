defmodule ResourceManager.Credentials.Cache do
  @moduledoc """
  Passwords credentials generic cache.

  We only cache the most common passwords list in order to verify
  before accepting an password.
  """

  use Nebulex.Cache, otp_app: :resource_manager, adapter: Nebulex.Adapters.Local
end
