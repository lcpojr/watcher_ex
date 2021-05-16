defmodule ResourceManager.Credentials.Commands.PasswordIsAllowed do
  @moduledoc """
  Comand for checking if a password is allowed or not.
  """

  require Logger

  alias ResourceManager.Credentials.BlocklistPasswordCache

  @doc "Checks if the given password is strong enough to be used"
  @spec execute(password :: String.t()) :: boolean()
  def execute(password) when is_binary(password) do
    Logger.info("Checking if password is allowed")

    with {:strong?, true} <- {:strong?, is_strong?(password)},
         {:blocklisted?, false} <- {:blocklisted?, is_blocklisted?(password)} do
      Logger.debug("Password allowed!")
      true
    else
      {:strong?, false} ->
        Logger.debug("Password not allowed because it's not strong enough")
        false

      {:blocklisted?, true} ->
        Logger.debug("Password not allowed because it's on blocklist")
        false
    end
  end

  defp is_strong?(password) when byte_size(password) >= 6, do: true
  defp is_strong?(password) when byte_size(password) < 6, do: false

  defp is_blocklisted?(password) do
    password
    |> BlocklistPasswordCache.get()
    |> case do
      nil -> false
      _any -> true
    end
  end
end
