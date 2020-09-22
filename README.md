# WatcherEx ![CI](https://github.com/lcpojr/watcher_ex/workflows/Continuous%20Integration/badge.svg)

**TODO: Add description**

## Requirements

- Elixir `1.10` using `OTP-23`;
- Erlang `23.0`;
- Docker-compose (Just when running in dev enviroment);

## Running it locally

First you should install all requirement, we recommend you to use [asdf](https://github.com/asdf-vm/asdf).

If you are using `asdf` just run:

- `asdf plugin-add elixir`;
- `asdf plugin-add erlang`;
- `asdf install`;

In order to prepare the application run:

- `docker-compose up` to get your containers running;
- `mix deps.get` to get all project dependencies;
- `mix setup` to create the database and run all migrations;

Now that you have everything configured you can just call `mix phx.server` to get all applications running. The service will be available at `localhost:4000`.

### Making requests

You can run the seeds in order to create an user and application for tests by using `mix seed`.
In order to gen you user and application data run on project iex (`iex -S mix phx.server`);

```elixir
ResourceManager.Repo.all(ResourceManager.Identity.Schemas.User) |> ResourceManager.Repo.preload([:scopes])
ResourceManager.Repo.all(ResourceManager.Identity.Schemas.ClientApplication) |> ResourceManager.Repo.preload([:scopes])
```

**Sign in by Resource Owner Flow**

Request:

```sh
curl -X POST http://localhost:4000/api/v1/auth/protocol/openid-connect/token \
    -H "Content-Type: application/json" \
    -d '{"username":"admin", "password":"admin", "grant_type":"password", "scope":"admin:read admin:write", "client_id": "2e455bb1-0604-4812-9756-36f7ab23b8d9", "client_secret": "$2b$12$BSrTLJnb0Vfuk1iiSzw3MehAvgztbMYpnhneVLQhkoZbxAXBGUCFe"}'
```

Response:

```json
{
    "access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMDc5NzU2NywiaWF0IjoxNjAwNzkwMzY3LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpY210ODQ3NTg1ZHQ5YzgwMDAxcDEiLCJuYmYiOjE2MDA3OTAzNjcsInNjb3BlIjoiYWRtaW46cmVhZCBhZG1pbjp3cml0ZSIsInN1YiI6IjdmNWViOWRjLWI1NTAtNDU4Ni05MWRjLTNjNzAxZWIzYjliYyIsInR5cCI6IkJlYXJlciJ9.LWniDC38j2kW8ER8kgDnVVJO0eOXWGNq0KqXooMl-5s",
    "refresh_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdGkiOiIyb3JpY210ODQ3NTg1ZHQ5YzgwMDAxcDEiLCJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMzM4MjM2NywiaWF0IjoxNjAwNzkwMzY3LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpY210OG5vbjRkZHQ5YzgwMDAxcTEiLCJuYmYiOjE2MDA3OTAzNjcsInR5cCI6IkJlYXJlciJ9.U010q6KUB04K8rIU9rVnW_AOI1q5XSXSGIYdL1moaOA",
    "expires_at":"1970-01-19T12:39:57.567",
    "scope":"admin:read admin:write"
}
```

**Sign in by Refresh Token Flow**

Request:

```sh
curl -X POST http://localhost:4000/api/v1/auth/protocol/openid-connect/token \
    -H "Content-Type: application/json" \
    -d '{"refresh_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdGkiOiIyb3JpY210ODQ3NTg1ZHQ5YzgwMDAxcDEiLCJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMzM4MjM2NywiaWF0IjoxNjAwNzkwMzY3LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpY210OG5vbjRkZHQ5YzgwMDAxcTEiLCJuYmYiOjE2MDA3OTAzNjcsInR5cCI6IkJlYXJlciJ9.U010q6KUB04K8rIU9rVnW_AOI1q5XSXSGIYdL1moaOA", "grant_type": "refresh_token"}'
```

Response:

```json
{
    "access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMDc5NzgwOSwiaWF0IjoxNjAwNzkwNjA5LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpZDUwYXRja3JiMzMyZWswMDAxczEiLCJuYmYiOjE2MDA3OTA2MDksInNjb3BlIjoiYWRtaW46cmVhZCBhZG1pbjp3cml0ZSIsInN1YiI6IjdmNWViOWRjLWI1NTAtNDU4Ni05MWRjLTNjNzAxZWIzYjliYyIsInR5cCI6IkJlYXJlciJ9.GnuyK5JTgg0PCeUtT79s847a3qPWgBjE8UqYoK1DG8o",
    "refresh_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdGkiOiIyb3JpZDUwYXRja3JiMzMyZWswMDAxczEiLCJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMzM4MjYwOSwiaWF0IjoxNjAwNzkwNjA5LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpZDUwYXRpOHJ2MzMyZWswMDAxdDEiLCJuYmYiOjE2MDA3OTA2MDksInR5cCI6IkJlYXJlciJ9.HIL0AMMKJdYUibSXyYXfYGBEMIZsuudvFUHcF-VjXRg",
    "expires_at":"1970-01-19T12:39:57.809",
    "scope":"admin:read admin:write"
}
```

**Sign out the given session**

Request:

```sh
curl -X POST http://localhost:4000/api/v1/sessions/logout \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMDgyMzMxNiwiaWF0IjoxNjAwODE2MTE2LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JqcmhuMHNxdDlncjk3ZXMwMDAzMDMiLCJuYmYiOjE2MDA4MTYxMTYsInNjb3BlIjoiYWRtaW46cmVhZCBhZG1pbjp3cml0ZSIsInN1YiI6IjdmNWViOWRjLWI1NTAtNDU4Ni05MWRjLTNjNzAxZWIzYjliYyIsInR5cCI6IkJlYXJlciJ9.NxFH6MIOFGc54UR9EVLPFB0m-6b-YMyXhZrOuGxErdw"
```

## Testing

Before you can run the tests you should setup the test dabatase by using `mix test_setup`. After that just call `mix test` or `mix coveralls` if you want to check code coverage.

### Code Quality

We use some libraries in order to keep our code as consistent as possible.

- [Credo](https://github.com/rrrene/credo) (run using `mix credo --strict`);
- [Dialyzer](https://github.com/jeremyjh/dialyxir) (run using `mix dialyzer`);
- [Coveralls](https://github.com/parroty/excoveralls) (run using `mix coveralls`);