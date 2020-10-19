defmodule RestAPI.Plugs.Authorization do
  @moduledoc """
  Provides authorization for public and admin calls.
  """

  require Logger

  alias RestAPI.Controllers.Fallback
  alias RestAPI.Ports.Authorizer

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{private: private} = conn, opts) when is_list(opts) do
    with {:authenticated?, true} <- {:authenticated?, has_session?(private)},
         {:authorized?, true} <- {:authorized?, authorized?(conn, opts[:type])} do
      conn
    else
      {:authenticated?, false} ->
        Logger.info("Session not found")
        Fallback.call(conn, {:error, :unauthorized})

      {:authorized?, false} ->
        Logger.info("Authorization failed in some policy")
        Fallback.call(conn, {:error, :unauthorized})
    end
  end

  defp has_session?(%{session: session}) when is_map(session), do: true
  defp has_session?(_any), do: false

  defp authorized?(conn, "admin") do
    conn
    |> Authorizer.authorize_admin()
    |> case do
      :ok -> true
      {:error, :unauthorized} -> false
    end
  end

  # We will start to authorize public endpoint on a next PR
  defp authorized?(_conn, _type), do: true
end
