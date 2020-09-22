defmodule RestAPI.View do
  @moduledoc """
  Helpers to be used in views.
  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.View, root: "lib/templates", namespace: RestAPI

      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      import Phoenix.View
      import RestAPI.Views.Errors.Helpers

      alias RestAPI.Router.Helpers, as: Routes
    end
  end
end
