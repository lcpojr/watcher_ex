defmodule Authenticator.SignIn.ApplicationAttemptsTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.SignIn.ApplicationAttempts
  alias Authenticator.SignIn.Schemas.ApplicationAttempt

  setup do
    {:ok, application_attempt: insert!(:application_sign_in_attempt)}
  end

  describe "#{ApplicationAttempts}.create/1" do
    test "succeed if params are valid" do
      params = %{
        client_id: Ecto.UUID.generate(),
        was_successful: true,
        ip_address: "45.232.192.12"
      }

      assert {:ok, %ApplicationAttempt{id: id} = application_attempt} =
               ApplicationAttempts.create(params)

      assert application_attempt == Repo.get(ApplicationAttempt, id)
    end

    test "fails if params are invalid" do
      assert {:error, changeset} = ApplicationAttempts.create(%{})

      assert %{
               client_id: ["can't be blank"],
               was_successful: ["can't be blank"],
               ip_address: ["can't be blank"]
             } = errors_on(changeset)
    end
  end

  describe "#{ApplicationAttempts}.update/2" do
    test "succeed if params are valid", ctx do
      assert {:ok, %ApplicationAttempt{id: id, was_successful: false} = application_attempt} =
               ApplicationAttempts.update(ctx.application_attempt, %{was_successful: false})

      assert application_attempt == Repo.get(ApplicationAttempt, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, changeset} =
               ApplicationAttempts.update(ctx.application_attempt, %{was_successful: 123})

      assert %{was_successful: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "#{ApplicationAttempts}.get_by/1" do
    test "succeed if params are valid", ctx do
      assert %ApplicationAttempt{} = ApplicationAttempts.get_by(id: ctx.application_attempt.id)
    end

    test "returns nil if nothing was found" do
      assert nil == ApplicationAttempts.get_by(id: Ecto.UUID.generate())
    end
  end

  describe "#{ApplicationAttempts}.list/1" do
    test "succeed if params are valid", ctx do
      assert [%ApplicationAttempt{}] = ApplicationAttempts.list(id: ctx.application_attempt.id)
    end

    test "returns empty list if nothing was found" do
      assert [] == ApplicationAttempts.list(id: Ecto.UUID.generate())
    end
  end

  describe "#{ApplicationAttempts}.delete/1" do
    test "succeed if params are valid", ctx do
      assert {:ok, %ApplicationAttempt{id: id}} =
               ApplicationAttempts.delete(ctx.application_attempt)

      assert nil == Repo.get(ApplicationAttempt, id)
    end

    test "raises if application_attempt does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        ApplicationAttempts.delete(%ApplicationAttempt{})
      end
    end
  end
end
