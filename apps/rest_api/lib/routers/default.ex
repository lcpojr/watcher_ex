defmodule RestAPI.Routers.Default do
  @moduledoc false

  use RestAPI.Router

  alias RestAPI.Routers.{Admin, Documentation, Public}

  forward "/admin", Admin
  forward "/api", Public
  forward "/", Documentation
end
