defmodule ResourceManager.MixProject do
  use Mix.Project

  @version_file "../../VERSION.txt"

  def project do
    [
      app: :resource_manager,
      version: version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
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
      mod: {ResourceManager.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # This makes sure your factory and any other modules in test/support are compiled
  # when in the test environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Domain
      {:argon2_elixir, "~> 2.4"},
      {:bcrypt_elixir, "~> 2.3"},
      {:pbkdf2_elixir, "~> 1.4"},
      {:nebulex, "~> 1.2"},
      {:jason, "~> 1.2"},
      {:eqrcode, "~> 0.1.8"},

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
        "ecto.create --quiet -r ResourceManager.Repo",
        "ecto.migrate -r ResourceManager.Repo",
        "test"
      ]
    ]
  end
end
