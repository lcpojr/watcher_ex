defmodule ResourceManager.Credentials.TOTPsTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Credentials.TOTPs
  alias ResourceManager.Credentials.Schemas.TOTP

  setup do
    user = insert!(:user)
    totp = insert!(:totp, user_id: user.id)

    {:ok, user: user, totp: totp}
  end

  describe "#{TOTPs}.create/1" do
    test "succeed if params are valid" do
      user = insert!(:user)
      params = %{user_id: user.id, username: user.username}
      assert {:ok, %TOTP{id: id, secret: secret, otp_uri: otp_uri} = totp} = TOTPs.create(params)
      assert totp.id == Repo.get(TOTP, id).id
      assert is_binary(secret) and is_binary(otp_uri)
    end

    test "fails if params are invalid", ctx do
      assert {:error, changeset} = TOTPs.create(%{user_id: ctx.user.id})
      assert %{username: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "#{TOTPs}.update/2" do
    test "succeed if params are valid", ctx do
      assert {:ok, %TOTP{id: id} = totp} =
               TOTPs.update(ctx.totp, %{username: ctx.user.username, issuer: "newIssuer"})

      assert totp.id == Repo.get(TOTP, id).id
    end

    test "fails if params are invalid", ctx do
      assert {:error, changeset} = TOTPs.update(ctx.totp, %{issuer: 123})
      assert %{issuer: ["is invalid"]} = errors_on(changeset)
    end

    test "raises if totp does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        TOTPs.update(%TOTP{}, %{
          user_id: Ecto.UUID.generate(),
          username: "username",
          issuer: "any_totp"
        })
      end
    end
  end

  describe "#{TOTPs}.get_by/1" do
    test "succeed if params are valid", ctx do
      assert %TOTP{} = TOTPs.get_by(id: ctx.totp.id)
    end

    test "returns nil if nothing was found" do
      assert nil == TOTPs.get_by(id: Ecto.UUID.generate())
    end
  end

  describe "#{TOTPs}.list/1" do
    test "succeed if params are valid", ctx do
      assert [%TOTP{}] = TOTPs.list(id: ctx.totp.id)
    end

    test "returns empty list if nothing was found" do
      assert [] == TOTPs.list(id: Ecto.UUID.generate())
    end
  end

  describe "#{TOTPs}.delete/1" do
    test "succeed if params are valid", ctx do
      assert {:ok, %TOTP{id: id}} = TOTPs.delete(ctx.totp)
      assert nil == Repo.get(TOTP, id)
    end

    test "raises if totp does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        TOTPs.delete(%TOTP{})
      end
    end
  end

  describe "#{TOTPs}.generate_totp_code/1" do
    test "succeeds and generates the totp code", ctx do
      assert code = TOTPs.generate_totp_code(ctx.totp)
      assert is_binary(code)
    end
  end

  describe "#{TOTPs}.generate_qr_code_base64/1" do
    test "succeeds and generates the totp qrcode", ctx do
      assert qrcode = TOTPs.generate_qr_code_base64(ctx.totp)
      assert is_binary(qrcode)
    end
  end

  describe "#{TOTPs}.valid_code?/1" do
    test "returns true if the verificode matches the secret", ctx do
      code = TOTPs.generate_totp_code(ctx.totp)
      assert true == TOTPs.valid_code?(ctx.totp, code)
    end

    test "returns false if the verificode matches the secret", ctx do
      assert false == TOTPs.valid_code?(ctx.totp, "anycode")
    end
  end
end
