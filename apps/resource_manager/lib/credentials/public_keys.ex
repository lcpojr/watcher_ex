defmodule ResourceManager.Credentials.PublicKeys do
  @moduledoc """
  Public keys are a type of credential used by a subject in authentication requests.

  It uses an asymmetric cryptography that means that pair of keys are generated and used
  by the subject. One of then is public and should be saved on our database and the other
  is privated and should only be known by the owner.

  When a subject requests an access_token it sign it's assertion using the private key and
  we use the public one to read it's content and validate the signature.
  """

  use ResourceManager.Domain, schema_model: ResourceManager.Credentials.Schemas.PublicKey
end
