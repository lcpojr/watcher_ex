for module <- [
      # ResourceManager domain
      Authenticator.Ports.ResourceManager
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
