defmodule ResourceManager.Credentials.TOTPs do
  @moduledoc """
  TOTPs (Time based on time password) are a type of credential used by a subject as
  an implementation of two factor autentication.

  This type of credential generates a one-time password which uses the current time as
  a source of uniqueness.
  """

  use ResourceManager.Domain, schema_model: ResourceManager.Credentials.Schemas.TOTP

  @doc """
  1- Backend server generates the secret key

  The server shares secret key with the service generating the OTP
  A hash based message authentication code (HMAC) is generated using the
    obtained secret key and time. This is done using the cryptographic
    SHA-1 algorithm.

  Since both the server and the device requesting the OTP, have access to time,
    which is obviously dynamic, it is taken as a parameter in the algorithm.
    Here, the Unix timestamp is considered which is independent of time
    zone i.e. time is calculated in seconds starting from January First 1970.

  Let us consider “0215a7d8c15b492e21116482b6d34fc4e1a9f6ba” as the generated
    string from the HMAC-SHA1 algorithm.

  The code generated is 20 bytes long and is thus truncated to the desired
    length suitable for the user to enter. Here dynamic truncation is used.
    For the 20-byte code “0215a7d8c15b492e21116482b6d34fc4e1a9f6ba”,
    each character occupies 4 bits. The entire string is taken as 20
      individual one byte sting. We look at the last character, here a.
    The decimal value of which is taken to determine the offset from which
    to begin truncation.

  Starting from the offset value, 10 the next 31 bits are read to obtain
    the string “6482b6d3″. The last thing left to do, is to take our
    hexadecimal numerical value, and convert it to decimal,
    which gives 1686288083.

  All we need now are the last desired length of OTP digits of the obtained
    decimal string, zero-padded if necessary.
    This is easily accomplished by taking the decimal string,
    modulo 10 ^ number of digits required in OTP.

    We end up with “288083” as our TOTP code.

    A counter is used to keep track of the time elapsed and generate a
      new code after a set interval of time

      OTP generated is delivered to user by the methods described above.
  """
  def generate_totp(%{secret: secret, period: period, digits: digits}, code) do
    decoded_secret = Base.decode32!(secret, padding: false)

    time_factor =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> Integer.floor_div(period)
      |> Integer.to_string()

    with hmac <- :crypto.hmac(:sha, decoded_secret, time_factor),
         <<_::19-binary, offset::1-binary>> <- hmac,
         <<_::size(offset)-binary, value::4-binary, _::binary>> <- hmac do
      value
    else
      _ -> :saiu
    end
  end
end
