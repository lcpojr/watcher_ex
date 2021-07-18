defmodule RestAPI.Ports.Authorizer do
  @moduledoc """
  Port to access Authorizer domain commands.
  """

  alias Plug.Conn

  @typedoc "All possible authorization responses"
  @type possible_authorize_response :: :ok | {:error, :unauthorized}

  @doc "Delegates to Authorizer.authorize_admin/1"
  @callback authorize_admin(conn :: Conn.t()) :: possible_authorize_response()

  @doc "Delegates to Authorizer.authorize_public/1"
  @callback authorize_public(conn :: Conn.t()) :: possible_authorize_response()

  @doc "Authorizes the subject using admin rule"
  @spec authorize_admin(conn :: Conn.t()) :: possible_authorize_response()
  def authorize_admin(conn), do: implementation().authorize_admin(conn)

  @doc "Authorizes the subject using public rule"
  @spec authorize_public(conn :: Conn.t()) :: possible_authorize_response()
  def authorize_public(conn), do: implementation().authorize_public(conn)

  defp implementation do
    :rest_api
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:domain)
  end
end
