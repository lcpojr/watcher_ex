defmodule Authenticator.Repo do
  @moduledoc false

  alias ResourceManager.Repo

  defdelegate insert(changeset_or_structs), to: Repo
  defdelegate insert(changeset_or_structs, opts), to: Repo

  defdelegate insert!(changeset_or_structs), to: Repo
  defdelegate insert!(changeset_or_structs, opts), to: Repo

  defdelegate insert_all(schema_or_source, entries), to: Repo
  defdelegate insert_all(schema_or_source, entries, opts), to: Repo

  defdelegate update(changeset_or_structs), to: Repo
  defdelegate update(changeset_or_structs, opts), to: Repo

  defdelegate update_all(queryable, updates), to: Repo
  defdelegate update_all(queryable, updates, opts), to: Repo

  defdelegate delete(changeset_or_structs), to: Repo
  defdelegate delete(changeset_or_structs, opts), to: Repo

  defdelegate transaction(fun_or_multi), to: Repo
  defdelegate transaction(fun_or_multi, opts), to: Repo

  defdelegate all(queryable), to: Repo
  defdelegate all(queryable, opts), to: Repo

  defdelegate one(queryable), to: Repo
  defdelegate one(queryable, opts), to: Repo

  defdelegate get(queryable, id), to: Repo
  defdelegate get(queryable, id, opts), to: Repo

  defdelegate get!(queryable, id), to: Repo
  defdelegate get!(queryable, id, opts), to: Repo

  defdelegate get_by(queryable, clauses), to: Repo
  defdelegate get_by(queryable, clauses, opts), to: Repo

  defdelegate get_by!(queryable, clauses), to: Repo
  defdelegate get_by!(queryable, clauses, opts), to: Repo

  defdelegate exists?(queryable), to: Repo
  defdelegate exists?(queryable, opts), to: Repo

  defdelegate preload(structs, preloads), to: Repo
  defdelegate preload(structs, preloads, opts), to: Repo
end
