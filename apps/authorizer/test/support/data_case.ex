defmodule Authorizer.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Query
      import Mox
      import Authorizer.{DataCase, Factory}

      setup :verify_on_exit!
    end
  end
end
