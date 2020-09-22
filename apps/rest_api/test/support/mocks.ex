for module <- [
      # Sign In ports domain
      RestAPI.Ports.SignIn
    ] do
  Mox.defmock(:"#{module}Mock", for: module)
end
