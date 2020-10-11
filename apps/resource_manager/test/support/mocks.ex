for module <- [
      # Credential ports mocks
      ResourceManager.Credentials.Ports.GenerateHash,
      ResourceManager.Credentials.Ports.VerifyHash,
      ResourceManager.Credentials.Ports.FakeVerifyHash,

      # Identity ports mocks
      ResourceManager.Identities.Ports.GetTemporarillyBlocked
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
