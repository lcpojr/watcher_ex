for module <- [
      # Authenticator
      ResourceManager.Ports.Authenticator
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
