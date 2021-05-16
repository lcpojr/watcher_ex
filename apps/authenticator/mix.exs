defmodule Authenticator.MixProject do
  use Mix.Project

  @version_file "../../VERSION.txt"

  def project do
    [
      app: :authenticator,
      version: version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp version do
    @version_file
    |> File.read!()
    |> String.trim()
  end

  def application do
    [
      mod: {Authenticator.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # This makes sure the factory and any other modules in test/support are compiled
  # when in the test environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Umbrella
      {:resource_manager, in_umbrella: true},

      # Domain
      {:argon2_elixir, "~> 2.4"},
      {:bcrypt_elixir, "~> 2.3"},
      {:pbkdf2_elixir, "~> 1.4"},
      {:joken, "~> 2.3"},
      {:jason, "~> 1.2"},
      {:nebulex, "~> 1.2"},

      # Database
      {:postgrex, "~> 0.15"},
      {:ecto_sql, "~> 3.6"},

      # Tools
      {:junit_formatter, "~> 3.2", only: [:test]},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:mox, "~> 0.5", only: :test}
    ]
  end

  defp aliases do
    [
      test: [
        "ecto.create --quiet -r Authenticator.Repo",
        "ecto.migrate -r Authenticator.Repo",
        "test"
      ]
    ]
  end
end
