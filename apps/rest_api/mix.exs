defmodule RestAPI.MixProject do
  use Mix.Project

  @version_file "../../VERSION.txt"

  def project do
    [
      app: :rest_api,
      version: version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
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
      mod: {RestAPI.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Umbrealla
      {:resource_manager, in_umbrella: true},
      {:authenticator, in_umbrella: true},
      {:authorizer, in_umbrella: true},

      # Domain
      {:phoenix, "~> 1.5.9"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.4"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},

      # Validations
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
      setup: ["deps.get"]
    ]
  end
end
