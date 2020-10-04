for module <- [
      # Authenticator domain
      RestAPI.Ports.Authenticator,

      # ResourceManager domain
      RestAPI.Ports.ResourceManager
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
