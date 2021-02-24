defmodule RestAPI.Factory do
  @moduledoc false

  alias ResourceManager.Identities.Schemas.User
  alias ResourceManager.Repo

  @doc "Builds a default struct from the requested model"
  @spec build(model :: atom()) :: struct()
  def build(:user) do
    %User{
      username: "my-test-username#{System.unique_integer()}",
      status: "active",
      is_admin: false
    }
  end

  @doc "Returns the a model struct with the given attributes"
  @spec build(factory_name :: atom(), attributes :: Keyword.t()) :: struct()
  def build(factory_name, attributes) when is_atom(factory_name) and is_list(attributes) do
    factory_name
    |> build()
    |> struct!(attributes)
  end

  @doc "Inserts a model with the given attributes on database"
  @spec insert!(factory_name :: atom(), attributes :: Keyword.t()) :: struct()
  def insert!(factory_name, attributes \\ []) when is_atom(factory_name) do
    factory_name
    |> build(attributes)
    |> Repo.insert!()
  end
end
