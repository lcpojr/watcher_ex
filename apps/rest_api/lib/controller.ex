defmodule RestApi.Controller do
  @moduledoc """
  Helpers to be used in controllers.
  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Controller, namespace: RestApi

      import Plug.Conn
      alias RestApi.Router.Helpers, as: Routes
    end
  end
end
