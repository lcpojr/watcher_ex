defmodule Authorizer.MixProject do
  use Mix.Project

  @version_file "../../VERSION.txt"

  def project do
    [
      app: :authorizer,
      version: version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp version do
    @version_file
    |> File.read!()
    |> String.trim()
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
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
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.0"},

      # Tools
      {:junit_formatter, "~> 3.2", only: [:test]},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:mox, "~> 0.5", only: :test}
    ]
  end
end
