defmodule RestApi.View do
  @moduledoc """
  Helpers to be used in views.
  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.View, root: "lib/templates", namespace: RestApi

      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      import Phoenix.View
      import RestApi.ErrorHelpers

      alias RestApi.Router.Helpers, as: Routes
    end
  end
end
