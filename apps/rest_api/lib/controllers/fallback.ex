defmodule RestAPI.Controllers.Fallback do
  @moduledoc false

  use Phoenix.Controller

  alias RestAPI.Views.Errors.Default

  @doc "Calls the correct fallback and renders it's response"
  @spec call(conn :: Plug.Conn.t(), error :: tuple()) :: Plug.Conn.t()
  def call(%Plug.Conn{} = conn, {:error, :invalid_params}) do
    conn
    |> put_status(:bad_request)
    |> put_view(Default)
    |> render("400.json")
  end

  def call(%Plug.Conn{} = conn, {:error, :unauthorized}) do
    conn
    |> put_status(:forbidden)
    |> put_view(Default)
    |> render("401.json")
  end

  def call(%Plug.Conn{} = conn, {:error, :unauthenticated}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(Default)
    |> render("403.json")
  end

  def call(%Plug.Conn{} = conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(Default)
    |> render("404.json")
  end

  def call(%Plug.Conn{} = conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:bad_request)
    |> put_view(Default)
    |> render("changeset.json", response: changeset)
  end

  def call(%Plug.Conn{} = conn, {:error, _unknown_error}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(Default)
    |> render("500.json")
  end
end
