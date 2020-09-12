for module <- [
      # Credential ports mocks
      ResourceManager.Credentials.Ports.HashSecret
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
