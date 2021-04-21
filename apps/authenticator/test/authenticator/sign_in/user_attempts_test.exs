defmodule Authenticator.SignIn.UserAttemptsTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.SignIn.Schemas.UserAttempt
  alias Authenticator.SignIn.UserAttempts

  setup do
    {:ok, user_attempt: insert!(:user_sign_in_attempt)}
  end

  describe "#{UserAttempts}.create/1" do
    test "succeed if params are valid" do
      params = %{
        username: Ecto.UUID.generate(),
        was_successful: true,
        ip_address: "45.232.192.12"
      }

      assert {:ok, %UserAttempt{id: id} = user_attempt} = UserAttempts.create(params)
      assert user_attempt == Repo.get(UserAttempt, id)
    end

    test "fails if params are invalid" do
      assert {:error, changeset} = UserAttempts.create(%{})

      assert %{
               username: ["can't be blank"],
               was_successful: ["can't be blank"],
               ip_address: ["can't be blank"]
             } = errors_on(changeset)
    end
  end

  describe "#{UserAttempts}.update/2" do
    test "succeed if params are valid", ctx do
      assert {:ok, %UserAttempt{id: id, was_successful: false} = user_attempt} =
               UserAttempts.update(ctx.user_attempt, %{was_successful: false})

      assert user_attempt == Repo.get(UserAttempt, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, changeset} = UserAttempts.update(ctx.user_attempt, %{was_successful: 123})
      assert %{was_successful: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "#{UserAttempts}.get_by/1" do
    test "succeed if params are valid", ctx do
      assert %UserAttempt{} = UserAttempts.get_by(id: ctx.user_attempt.id)
    end

    test "returns nil if nothing was found" do
      assert nil == UserAttempts.get_by(id: Ecto.UUID.generate())
    end
  end

  describe "#{UserAttempts}.list/1" do
    test "succeed if params are valid", ctx do
      assert [%UserAttempt{}] = UserAttempts.list(id: ctx.user_attempt.id)
    end

    test "returns empty list if nothing was found" do
      assert [] == UserAttempts.list(id: Ecto.UUID.generate())
    end
  end

  describe "#{UserAttempts}.delete/1" do
    test "succeed if params are valid", ctx do
      assert {:ok, %UserAttempt{id: id}} = UserAttempts.delete(ctx.user_attempt)
      assert nil == Repo.get(UserAttempt, id)
    end

    test "raises if user_attempt does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        UserAttempts.delete(%UserAttempt{})
      end
    end
  end
end
