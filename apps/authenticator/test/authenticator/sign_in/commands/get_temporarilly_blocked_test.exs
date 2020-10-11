defmodule Authenticator.SignIn.Commands.GetTemporarillyBlockedTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.SignIn.Commands.GetTemporarillyBlocked

  describe "#{GetTemporarillyBlocked}.execute/1" do
    test "succeeds and return users to block temporarilly" do
      assert [%{username: username} | _] =
               Enum.map(1..15, fn _ ->
                 insert!(:user_sign_in_attempt, username: "myusername", was_successful: false)
               end)

      assert {:ok, [^username | _]} = GetTemporarillyBlocked.execute(:user)
    end

    test "succeeds and return applications to block temporarilly" do
      assert [%{client_id: client_id} | _] =
               Enum.map(1..15, fn _ ->
                 insert!(:application_sign_in_attempt,
                   client_id: "myclientid",
                   was_successful: false
                 )
               end)

      assert {:ok, [^client_id | _]} = GetTemporarillyBlocked.execute(:application)
    end
  end
end
