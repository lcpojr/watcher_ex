defmodule Authenticator.SignIn.RefreshToken do
  @moduledoc """
  Re authenticates the user identity using the Resource Token Flow.

  This flow is used in order to exchange a refresh token in a new access token
  when the access token has expired.

  This allows clients to continue to have a valid access token without further
  interaction with the user.
  """

  require Logger

  alias Authenticator.Sessions.{AccessToken, RefreshToken}
  alias Authenticator.SignIn.Inputs.RefreshToken, as: Input

  @typedoc "All possible responses"
  @type possible_responses ::
          {:ok, %{access_token: String.t(), refresh_token: String.t()}}
          | {:error, Ecto.Changeset.t() | :anauthenticated}

  @doc "Sign in an user identity by RefreshToken flow"
  @spec execute(input :: Input.t() | map()) :: possible_responses()
  def execute(%Input{refresh_token: refresh_token}) do
    with {:token, {:ok, claims}} <- {:token, RefreshToken.verify_and_validate(refresh_token)} do
      {:ok, %{access_token: "", refresh_token: ""}}
    else
      {:token, {:error, reason}} ->
        Logger.error("Failed to validate refresh token", error: inspect(reason))
        {:error, :unauthenticated}

      {:app, {:error, :not_found}} ->
        Logger.info("Client application not found")
        {:error, :unauthenticated}
    end
  end
end
