defmodule WatcherEx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/lcpojr/watcher_ex"
  @maintainers ["Luiz Carlos"]
  @licenses ["Apache 2.0"]

  def project do
    [
      apps_path: "apps",
      version: @version,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      aliases: aliases(),
      package: package(),
      description: description(),
      source_url: @url,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "ecto.test_setup": :test,
        "ecto.test_reset": :test
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      # Tools
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:excoveralls, "~> 0.13", only: :test}
    ]
  end

  defp description, do: "Elixir OAuth2 server"

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
        ecto_sql: "https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.html",
        argon2_elixir: "https://hexdocs.pm/argon2_elixir/api-reference.html"
      ]
    ]
  end

  defp aliases do
    [
      "ecto.setup": [
        "ecto.create -r ResourceManager.Repo",
        "ecto.migrate -r ResourceManager.Repo"
      ],
      "ecto.reset": [
        "ecto.drop -r ResourceManager.Repo",
        "ecto.setup"
      ],
      "ecto.test_setup": [
        "ecto.create -r ResourceManager.Repo",
        "ecto.migrate -r ResourceManager.Repo"
      ],
      "ecto.test_reset": [
        "ecto.drop -r ResourceManager.Repo",
        "ecto.test_setup"
      ],
      test: [
        "ecto.create --quiet -r ResourceManager.Repo",
        "ecto.migrate -r ResourceManager.Repo",
        "test"
      ]
    ]
  end
end
