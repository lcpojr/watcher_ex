# RestAPI

This application handles all requests on the restfull api.
It exposes public and admin endpoints.

## Testing it locally

Follow the `Running it locally` guide on project `README.md` in order to know how to install all dependencies and get the server ready.

### Sign in by Resource Owner Flow

**Request (Client assertions)**:

To generate the client assertions follow the exemple bellow (in the project iex):

```elixir
signer = Joken.Signer.create("RS256", %{"pem" => "YOUR_PRIVATE_KEY_HERE"})

Authenticator.ClientAssertion.generate_and_sign!(%{"iss" => "YOUR_APP_CLIENT_ID", "aud" => "WatcherEx", "typ" => "Bearer"}, signer)
```

Then you can try out the request using:

```sh
curl -X POST http://localhost:4000/api/v1/auth/protocol/openid-connect/token \
    -H "Content-Type: application/json" \
    -d '{"username":"admin", "password":"admin", "grant_type":"password", "scope":"admin:read admin:write", "client_id": "2e455bb1-0604-4812-9756-36f7ab23b8d9", "client_assertion": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJXYXRjaGVyRXgiLCJleHAiOjE2MDEyMzgwOTMsImlhdCI6MTYwMTIzMDg5MywiaXNzIjoiMmU0NTViYjEtMDYwNC00ODEyLTk3NTYtMzZmN2FiMjNiOGQ5IiwianRpIjoiMm9zYmUwc3JrbTMyc2tvN2ZrMDAwMnAzIiwibmJmIjoxNjAxMjMwODkzLCJ0eXAiOiJCZWFyZXIifQ.SDUlLMO9kVLfxyRRJUCCVPpz2fcjUtxC1K3IJPa2NrBp7S-IUGuZx9965M09jFJOZrNzqEC9VRZb9KqlZS2T0bGUg3pk8R91oqOgnPOvXEQ8bjTKuvqIv7K7hKaAARxRTgBf-o87quUoVoZzepLzfmJdnDVXy0QoFIO7_SYe4zmq3mrrvHM5Kaypgf0JMiOZORr2kEnk0zEkPoIvqL8psTrLlaUHr-cn3l3F7eGARhHijOTXoFXTH4BFjJzsQJRKcz1cyzUQ64Y02JWeYsbfi1higF14lGnFTduuVwMpqa7Wu5xK9FhmR1mmlqqFgD6NVeiDxoDcAzhhDbQWdKuuAyqyr67uYfY5qeeudoKYyJcjvfE0c1iMLpEQAlZDK_HjoChBEORcTcvbsCD-75y2lJhqsrW0cTWoqq0YTXU3SHvdewEZto8AEaQMKHnGozQQEkeF7rOFOJF7P_LX2LV7JbtxIl8RZPvjNNF6F6VHy_DJTVoJJNbIRRm47v8fXBBej60_76XZmxG_FtgZBevVgINq_lnYf2nb_2RybxyzRxfC4pRvTh6Og8mZy5fcgYIa4Yq3eXdDVAVxrFJWrJqfjdPSuZbFDuq6VfiXOAd_bNqNHMLN_jiTtJlVJnS-gk9Ejot8X-kwG-UPDoAQZIfyBqMSXIqyL-qFfVR8dIX9Dps", "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"}'
```


**Request (Client secret)**:

```sh
curl -X POST http://localhost:4000/api/v1/auth/protocol/openid-connect/token \
    -H "Content-Type: application/json" \
    -d '{"username":"admin", "password":"admin", "grant_type":"password", "scope":"admin:read admin:write", "client_id": "2e455bb1-0604-4812-9756-36f7ab23b8d9", "client_secret": "$2b$12$BSrTLJnb0Vfuk1iiSzw3MehAvgztbMYpnhneVLQhkoZbxAXBGUCFe"}'
```

**Response (200)**:

```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMDc5NzU2NywiaWF0IjoxNjAwNzkwMzY3LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpY210ODQ3NTg1ZHQ5YzgwMDAxcDEiLCJuYmYiOjE2MDA3OTAzNjcsInNjb3BlIjoiYWRtaW46cmVhZCBhZG1pbjp3cml0ZSIsInN1YiI6IjdmNWViOWRjLWI1NTAtNDU4Ni05MWRjLTNjNzAxZWIzYjliYyIsInR5cCI6IkJlYXJlciJ9.LWniDC38j2kW8ER8kgDnVVJO0eOXWGNq0KqXooMl-5s",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdGkiOiIyb3JpY210ODQ3NTg1ZHQ5YzgwMDAxcDEiLCJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMzM4MjM2NywiaWF0IjoxNjAwNzkwMzY3LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpY210OG5vbjRkZHQ5YzgwMDAxcTEiLCJuYmYiOjE2MDA3OTAzNjcsInR5cCI6IkJlYXJlciJ9.U010q6KUB04K8rIU9rVnW_AOI1q5XSXSGIYdL1moaOA",
    "expires_in": 7200000,
    "token_type": "Bearer"
}
```

### Sign in by Refresh Token Flow

**Request**:

```sh
curl -X POST http://localhost:4000/api/v1/auth/protocol/openid-connect/token \
    -H "Content-Type: application/json" \
    -d '{"refresh_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdGkiOiIyb3JpY210ODQ3NTg1ZHQ5YzgwMDAxcDEiLCJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMzM4MjM2NywiaWF0IjoxNjAwNzkwMzY3LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpY210OG5vbjRkZHQ5YzgwMDAxcTEiLCJuYmYiOjE2MDA3OTAzNjcsInR5cCI6IkJlYXJlciJ9.U010q6KUB04K8rIU9rVnW_AOI1q5XSXSGIYdL1moaOA", "grant_type": "refresh_token"}'
```

**Response (200)**:

```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMDc5NzgwOSwiaWF0IjoxNjAwNzkwNjA5LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpZDUwYXRja3JiMzMyZWswMDAxczEiLCJuYmYiOjE2MDA3OTA2MDksInNjb3BlIjoiYWRtaW46cmVhZCBhZG1pbjp3cml0ZSIsInN1YiI6IjdmNWViOWRjLWI1NTAtNDU4Ni05MWRjLTNjNzAxZWIzYjliYyIsInR5cCI6IkJlYXJlciJ9.GnuyK5JTgg0PCeUtT79s847a3qPWgBjE8UqYoK1DG8o",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdGkiOiIyb3JpZDUwYXRja3JiMzMyZWswMDAxczEiLCJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMzM4MjYwOSwiaWF0IjoxNjAwNzkwNjA5LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpZDUwYXRpOHJ2MzMyZWswMDAxdDEiLCJuYmYiOjE2MDA3OTA2MDksInR5cCI6IkJlYXJlciJ9.HIL0AMMKJdYUibSXyYXfYGBEMIZsuudvFUHcF-VjXRg",
    "expires_in": 7200000,
    "token_type": "Bearer"
}
```

### Sign in by Client Credentials Flow

**Request (Client Assertions)**:

To generate the client assertions follow the exemple bellow (in the project iex):

```elixir
signer = Joken.Signer.create("RS256", %{"pem" => "YOUR_PRIVATE_KEY_HERE"})

Authenticator.ClientAssertion.generate_and_sign!(%{"iss" => "YOUR_APP_CLIENT_ID", "aud" => "WatcherEx", "typ" => "Bearer"}, signer)
```

Then you can try out the request using:

```sh
curl -X POST http://localhost:4000/api/v1/auth/protocol/openid-connect/token \
    -H "Content-Type: application/json" \
    -d '{"grant_type":"client_credentials", "scope":"admin:read admin:write", "client_id": "2e455bb1-0604-4812-9756-36f7ab23b8d9", "client_assertion": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJXYXRjaGVyRXgiLCJleHAiOjE2MDEyMzgwOTMsImlhdCI6MTYwMTIzMDg5MywiaXNzIjoiMmU0NTViYjEtMDYwNC00ODEyLTk3NTYtMzZmN2FiMjNiOGQ5IiwianRpIjoiMm9zYmUwc3JrbTMyc2tvN2ZrMDAwMnAzIiwibmJmIjoxNjAxMjMwODkzLCJ0eXAiOiJCZWFyZXIifQ.SDUlLMO9kVLfxyRRJUCCVPpz2fcjUtxC1K3IJPa2NrBp7S-IUGuZx9965M09jFJOZrNzqEC9VRZb9KqlZS2T0bGUg3pk8R91oqOgnPOvXEQ8bjTKuvqIv7K7hKaAARxRTgBf-o87quUoVoZzepLzfmJdnDVXy0QoFIO7_SYe4zmq3mrrvHM5Kaypgf0JMiOZORr2kEnk0zEkPoIvqL8psTrLlaUHr-cn3l3F7eGARhHijOTXoFXTH4BFjJzsQJRKcz1cyzUQ64Y02JWeYsbfi1higF14lGnFTduuVwMpqa7Wu5xK9FhmR1mmlqqFgD6NVeiDxoDcAzhhDbQWdKuuAyqyr67uYfY5qeeudoKYyJcjvfE0c1iMLpEQAlZDK_HjoChBEORcTcvbsCD-75y2lJhqsrW0cTWoqq0YTXU3SHvdewEZto8AEaQMKHnGozQQEkeF7rOFOJF7P_LX2LV7JbtxIl8RZPvjNNF6F6VHy_DJTVoJJNbIRRm47v8fXBBej60_76XZmxG_FtgZBevVgINq_lnYf2nb_2RybxyzRxfC4pRvTh6Og8mZy5fcgYIa4Yq3eXdDVAVxrFJWrJqfjdPSuZbFDuq6VfiXOAd_bNqNHMLN_jiTtJlVJnS-gk9Ejot8X-kwG-UPDoAQZIfyBqMSXIqyL-qFfVR8dIX9Dps", "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"}'
```

**Request (client secret)**:

```sh
curl -X POST http://localhost:4000/api/v1/auth/protocol/openid-connect/token \
    -H "Content-Type: application/json" \
    -d '{"grant_type":"client_credentials", "scope":"admin:read admin:write", "client_id": "2e455bb1-0604-4812-9756-36f7ab23b8d9", "client_secret": "$2b$12$BSrTLJnb0Vfuk1iiSzw3MehAvgztbMYpnhneVLQhkoZbxAXBGUCFe"}'
```

**Response (200)**:

```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMDc5NzU2NywiaWF0IjoxNjAwNzkwMzY3LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpY210ODQ3NTg1ZHQ5YzgwMDAxcDEiLCJuYmYiOjE2MDA3OTAzNjcsInNjb3BlIjoiYWRtaW46cmVhZCBhZG1pbjp3cml0ZSIsInN1YiI6IjdmNWViOWRjLWI1NTAtNDU4Ni05MWRjLTNjNzAxZWIzYjliYyIsInR5cCI6IkJlYXJlciJ9.LWniDC38j2kW8ER8kgDnVVJO0eOXWGNq0KqXooMl-5s",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdGkiOiIyb3JpY210ODQ3NTg1ZHQ5YzgwMDAxcDEiLCJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMzM4MjM2NywiaWF0IjoxNjAwNzkwMzY3LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpY210OG5vbjRkZHQ5YzgwMDAxcTEiLCJuYmYiOjE2MDA3OTAzNjcsInR5cCI6IkJlYXJlciJ9.U010q6KUB04K8rIU9rVnW_AOI1q5XSXSGIYdL1moaOA",
    "expires_in": 7200000,
    "token_type": "Bearer"
}
```

### Sign out all active sessions

**Request**:

```sh
curl -X POST http://localhost:4000/api/v1/auth/protocol/openid-connect/logout-all-sessions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMTE1NzEyNCwiaWF0IjoxNjAxMTQ5OTI0LCJpZGVudGl0eSI6InVzZXIiLCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3M2cW5zN2ZxYjFvOGhrZDQwMDAxNTQiLCJuYmYiOjE2MDExNDk5MjQsInNjb3BlIjoiYWRtaW46cmVhZCBhZG1pbjp3cml0ZSIsInN1YiI6IjIyZTk2MTA4LThkZDYtNGZiZS1iMjExLTY4OTM0YmJhNWJkNyIsInR0bCI6NzIwMCwidHlwIjoiQmVhcmVyIn0.EuIJtx_AGLrL2O7E7cBfsvEQymalO_A5-J0BX4PODwk"
```

**Response (204)**:

`No content`

### Sign out the given session

**Request**:

```sh
curl -X POST http://localhost:4000/api/v1/auth/protocol/openid-connect/logout \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMDgyMzMxNiwiaWF0IjoxNjAwODE2MTE2LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JqcmhuMHNxdDlncjk3ZXMwMDAzMDMiLCJuYmYiOjE2MDA4MTYxMTYsInNjb3BlIjoiYWRtaW46cmVhZCBhZG1pbjp3cml0ZSIsInN1YiI6IjdmNWViOWRjLWI1NTAtNDU4Ni05MWRjLTNjNzAxZWIzYjliYyIsInR5cCI6IkJlYXJlciJ9.NxFH6MIOFGc54UR9EVLPFB0m-6b-YMyXhZrOuGxErdw"
```

**Response (204)**:

`No content`