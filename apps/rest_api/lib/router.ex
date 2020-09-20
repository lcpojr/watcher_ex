defmodule RestApi.Router do
  @moduledoc """
  Helpers to be used in routers.
  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end
end
