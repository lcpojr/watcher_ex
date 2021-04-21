defmodule RestAPI.Routers.Default do
  @moduledoc false

  use RestAPI.Router

  alias RestAPI.Routers.{Admin, Public}

  forward "/admin", Admin
  forward "/api", Public
end
