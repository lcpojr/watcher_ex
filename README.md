# WatcherEx ![Build](https://github.com/lcpojr/watcher_ex/workflows/CI/badge.svg) [![Coverage](https://coveralls.io/repos/github/lcpojr/watcher_ex/badge.svg)](https://coveralls.io/github/lcpojr/watcher_ex)

WatcherEx is an Oauth2 provider made entirely in elixir.

## Requirements

- Elixir `1.11`;
- Erlang `23.1`;
- Docker-compose (Just when running in dev enviroment);

## Running it locally

In order to prepare the application run:

- `docker-compose up` to get your containers running;
- `mix deps.get` to get all project dependencies;
- `mix setup` to create the database and run all migrations;

Now that you have everything configured you can just call `mix phx.server` to get all applications running. The service will be available at `localhost:4000`.

### Seeding the database

You can run the seeds in order to create an user and application for tests by using `mix seed`.
To get the user and application data check out the database on `localhost:8181` or run the project with using (`iex -S mix phx.server`) and execute the commands bellow.

```elixir
# Getting all user identities
# The user password will be `admin`
ResourceManager.Repo.all(ResourceManager.Identities.Schemas.User) |> ResourceManager.Repo.preload([:scopes])

# Getting all client application identities
# Check out for the client secret
ResourceManager.Repo.all(ResourceManager.Identities.Schemas.ClientApplication) |> ResourceManager.Repo.preload([:scopes])
```

### Making requests

Check out the [rest api guide](https://github.com/lcpojr/watcher_ex/blob/master/apps/rest_api/README.md) on the specific application `README.md` or you can check it out on or live example [here](https://watcherex.gigalixirapp.com/api/v1/swagger/index.html).

### Testing

Before you can run the tests you should setup the test dabatase by using `mix test_setup`. After that just call `mix test` or `mix coveralls` if you want to check code coverage.

### Code Quality

We use some libraries in order to keep our code as consistent as possible.

- [Credo](https://github.com/rrrene/credo) (run using `mix credo --strict`);
- [Dialyzer](https://github.com/jeremyjh/dialyxir) (run using `mix dialyzer`);
- [Coveralls](https://github.com/parroty/excoveralls) (run using `mix coveralls`);
