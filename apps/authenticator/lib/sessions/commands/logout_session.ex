defmodule Authenticator.Sessions.Commands.LogoutSession do
  @moduledoc false

  def execute(_), do: {:ok, :logouted}
end