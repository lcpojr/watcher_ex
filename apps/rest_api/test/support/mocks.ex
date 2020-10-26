for module <- [
      # Authenticator domain
      RestAPI.Ports.Authenticator,

      # Authorizer domain
      RestAPI.Ports.Authorizer,

      # ResourceManager domain
      RestAPI.Ports.ResourceManager
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
