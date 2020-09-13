for module <- [
      # Credential ports mocks
      ResourceManager.Credentials.Ports.GenerateHash,
      ResourceManager.Credentials.Ports.VerifyHash
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
