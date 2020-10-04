defmodule RestAPI.Controller do
  @moduledoc """
  Helpers to be used in controllers.
  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Controller, namespace: RestAPI

      import Plug.Conn

      alias RestAPI.Router.Helpers, as: Routes

      @doc "Gets the remote_ip from connection and parses into a string"
      @spec get_remote_ip(conn :: Plug.Conn.t()) :: String.t()
      def get_remote_ip(conn) do
        conn.remote_ip
        |> :inet_parse.ntoa()
        |> to_string()
      end
    end
  end
end
