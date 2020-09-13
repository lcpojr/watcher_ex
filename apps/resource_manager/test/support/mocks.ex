for module <- [
      # Credential ports mocks
      ResourceManager.Credentials.Ports.GenerateHash,
      ResourceManager.Credentials.Ports.VerifyHash,
      ResourceManager.Credentials.Ports.FakeVerifyHash
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
