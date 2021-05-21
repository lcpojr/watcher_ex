defmodule WatcherEx.MixProject do
  use Mix.Project

  @url "https://github.com/lcpojr/watcher_ex"
  @maintainers ["Luiz Carlos"]
  @licenses ["Apache-2.0"]
  @version_file "VERSION.txt"

  def project do
    [
      apps_path: "apps",
      version: version(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: "An OAuth2 provider interelly in elixir.",
      source_url: @url,
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      elixirc_options: [warnings_as_errors: true],
      preferred_cli_env: preferred_cli_env(),
      aliases: aliases(),
      releases: releases()
    ]
  end

  defp version do
    @version_file
    |> File.read!()
    |> String.trim()
  end

  defp deps do
    [
      # Tools
      {:junit_formatter, "~> 3.2", only: [:test]},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:mox, "~> 0.5", only: :test}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.txt", "CHANGELOG.md"],
      maintainers: @maintainers,
      licenses: @licenses,
      links: %{
        "GitHub" => "https://github.com/lcpojr/watcher_ex",
        "Docs" => "http://hexdocs.pm/watcher_ex"
      }
    ]
  end

  defp docs do
    [
      main: "WatcherEx",
      extras: ["README.md"],
      deps: [
        ecto_sql: "https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.html"
      ]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit],
      plt_core_path: "dialyzer/plts/",
      plt_file: {:no_warn, "dialyzer/plts/watcher_ex.plt"},
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      test_setup: :test,
      test_reset: :test
    ]
  end

  defp aliases do
    [
      setup: ["ecto.create", "ecto.migrate"],
      reset: ["ecto.drop", "setup"],
      test_setup: ["ecto.create", "ecto.migrate"],
      test_reset: ["ecto.drop", "test_setup"],
      seed: ["run apps/resource_manager/priv/repo/seeds.exs"],
      test: ["test"]
    ]
  end

  defp releases do
    [
      watcher_ex: [
        version: version(),
        include_executables_for: [:unix],
        applications: [
          resource_manager: :permanent,
          authorizer: :permanent,
          authenticator: :permanent,
          rest_api: :permanent
        ]
      ]
    ]
  end
end
