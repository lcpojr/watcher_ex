defmodule RestAPI.Ports.Authenticator do
  @moduledoc """
  Port to access Authenticator domain commands.
  """

  @typedoc "Token parameters to be sent on responses"
  @type token_params :: %{
          access_token: String.t(),
          refresh_token: String.t(),
          expires_at: NaiveDateTime.t(),
          scope: String.t()
        }

  @typedoc "All possible sign in responses"
  @type possible_sign_in_responses ::
          {:ok, token_params()}
          | {:error, Ecto.Changeset.t() | :anauthenticated}

  @typedoc "All possible logout responses"
  @type possible_logout_failures :: {:error, Ecto.Changeset.t() | :not_found | :not_active}

  @doc "Delegates to Authenticator.sign_in_resource_owner/1"
  @callback sign_in_resource_owner(input :: map()) :: possible_sign_in_responses()

  @doc "Delegates to Authenticator.sign_in_refresh_token/1"
  @callback sign_in_refresh_token(input :: map()) :: possible_sign_in_responses()

  @doc "Delegates to Authenticator.get_session/1"
  @callback get_session(input :: map()) :: struct()

  @doc "Delegates to Authenticator.validate_access_token/1"
  @callback validate_access_token(token :: String.t()) :: {:ok, map()} | {:error, Keyword.t()}

  @doc "Delegates to Authenticator.sign_out_session/1"
  @callback sign_out_session(session_or_jti :: struct() | String.t()) ::
              {:ok, session :: struct()} | possible_logout_failures()

  @doc "Delegates to Authenticator.sign_out_all_sessions/2"
  @callback sign_out_all_sessions(subject_id :: String.t(), subject_type :: String.t()) ::
              {:ok, count :: integer()} | possible_logout_failures()

  @doc "Authenticates the subject using Resource Owner Flow"
  @spec sign_in_resource_owner(input :: map()) :: possible_sign_in_responses()
  def sign_in_resource_owner(input), do: implementation().sign_in_resource_owner(input)

  @doc "Authenticates the subject using Refresh Token Flow"
  @spec sign_in_refresh_token(input :: map()) :: possible_sign_in_responses()
  def sign_in_refresh_token(input), do: implementation().sign_in_refresh_token(input)

  @doc "Validates a given access token and it's claims"
  @spec validate_access_token(access_token :: String.t()) :: {:ok, map()} | {:error, Keyword.t()}
  def validate_access_token(token), do: implementation().validate_access_token(token)

  @doc "Get's a session by the given input filters"
  @spec get_session(input :: map()) :: {:ok, struct()} | {:error, :not_found}
  def get_session(input), do: implementation().get_session(input)

  @doc "Invalidates a given session"
  @spec sign_out_session(session_or_jti :: map()) :: {:ok, struct()} | possible_logout_failures()
  def sign_out_session(session_or_jti), do: implementation().sign_out_session(session_or_jti)

  @doc "Invalidates all subject sessions"
  @spec sign_out_all_sessions(subject_id :: String.t(), subject_type :: String.t()) ::
          {:ok, count :: integer()} | possible_logout_failures()
  def sign_out_all_sessions(sub, type), do: implementation().sign_out_all_sessions(sub, type)

  defp implementation do
    :rest_api
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:domain)
  end
end
