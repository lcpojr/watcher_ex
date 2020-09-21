defmodule RestAPI.Controller do
  @moduledoc """
  Helpers to be used in controllers.
  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Controller, namespace: RestAPI

      import Plug.Conn
      alias RestAPI.Router.Helpers, as: Routes
    end
  end
end
