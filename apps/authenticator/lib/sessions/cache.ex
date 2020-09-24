defmodule Authenticator.Sessions.Cache do
  @moduledoc """
  Sessions generic cache.

  This is important to avoid be going on database in any request and
  to be faster in authentication requests.
  """

  use Nebulex.Cache, otp_app: :my_app, adapter: Nebulex.Adapters.Local
end
