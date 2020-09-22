for module <- [
      # Authenticator domain
      RestAPI.Ports.Authenticator
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
