defmodule ResourceManager.Credentials.TOTPs do
  @moduledoc """
  TOTPs (Time based on time password) are a type of credential used by a subject as
  an implementation of two factor autentication.

  This type of credential generates a one-time password which uses the current time as
  a source of uniqueness.
  """

  use ResourceManager.Domain, schema_model: ResourceManager.Credentials.Schemas.TOTP

  alias ResourceManager.Credentials.Schemas.TOTP

  @doc """
  Generate Time-Based One-Time Password totp verification code.

  In order to generate the correct verification code we have to follow the steps bellow:
    - Receive the user local timestamp (or use the server);
    - Decode the TOTP secret in base32 (it's encoded on totp creation);
    - Get the moving factor based on the configured period and the actual or given timestamp;
    - Generates the HMAC using the secret and the moving factor;
    - Truncate the HMAC in order to get the last 31 bits extracting the offset first;
    - Parsing the truncated bits into an string with the size of the configured digits;

  ## Options:
    - `time` - The user local time in unix format. Default is `System.os_time(:second)`
  """
  @spec generate_totp_code(totp :: TOTP.t(), opts :: Keyword.t()) :: String.t()
  def generate_totp_code(%TOTP{} = totp, opts \\ []) do
    time = opts[:time] || System.os_time(:second)

    # Decoding the secret in base32
    key =
      totp.secret
      |> String.upcase()
      |> Base.decode32!(padding: false)

    # Extracting moving factor
    moving_factor = <<Integer.floor_div(time, totp.period)::64>>

    # Generating hmac from secret and moving factor
    hmac = :crypto.mac(:hmac, :sha, key, moving_factor)

    # Truncating hmac and extracting verification code
    <<_::19-binary, _::4, offset::4>> = hmac
    <<_::size(offset)-binary, p::4-binary, _::binary>> = hmac
    <<_::1, trucated_bits::31>> = p

    # Parsing truncated bits into verification code
    trucated_bits
    |> rem(1_000_000)
    |> to_string()
    |> String.pad_leading(totp.digits, "0")
  end

  @doc "Checks if the given totp code matchs the secret"
  @spec valid_code?(totp :: TOTP.t(), totp_code :: String.t()) :: boolean()
  def valid_code?(%TOTP{} = totp, totp_code) when is_binary(totp_code),
    do: generate_totp_code(totp) == totp_code

  @doc "Generates an QRCode for the given totp uri encoded in base64"
  @spec generate_qr_code_base64(totp :: TOTP.t()) :: String.t()
  def generate_qr_code_base64(%TOTP{} = totp) do
    totp.otp_uri
    |> EQRCode.encode()
    |> EQRCode.png()
    |> Base.encode64(padding: false)
  end
end
