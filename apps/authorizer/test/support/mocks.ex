for module <- [
      # ResourceManager domain
      Authorizer.Ports.ResourceManager
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
