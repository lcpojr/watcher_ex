defmodule RestAPI.Swagger.AuthOperations do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use PhoenixSwagger

      alias PhoenixSwagger.Schema

      ###########
      # Requests
      ###########

      @client_id "2e455bb1-0604-4812-9756-36f7ab23b8d9"
      @client_secret "$2b$12$BSrTLJnb0Vfuk1iiSzw3MehAvgztbMYpnhneVLQhkoZbxAXBGUCFe"
      @client_assertion "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJXYXRjaGVyRXgiLCJleHAiOjE2MDEyMzgwOTMsImlhdCI6MTYwMTIzMDg5MywiaXNzIjoiMmU0NTViYjEtMDYwNC00ODEyLTk3NTYtMzZmN2FiMjNiOGQ5IiwianRpIjoiMm9zYmUwc3JrbTMyc2tvN2ZrMDAwMnAzIiwibmJmIjoxNjAxMjMwODkzLCJ0eXAiOiJCZWFyZXIifQ.SDUlLMO9kVLfxyRRJUCCVPpz2fcjUtxC1K3IJPa2NrBp7S-IUGuZx9965M09jFJOZrNzqEC9VRZb9KqlZS2T0bGUg3pk8R91oqOgnPOvXEQ8bjTKuvqIv7K7hKaAARxRTgBf-o87quUoVoZzepLzfmJdnDVXy0QoFIO7_SYe4zmq3mrrvHM5Kaypgf0JMiOZORr2kEnk0zEkPoIvqL8psTrLlaUHr-cn3l3F7eGARhHijOTXoFXTH4BFjJzsQJRKcz1cyzUQ64Y02JWeYsbfi1higF14lGnFTduuVwMpqa7Wu5xK9FhmR1mmlqqFgD6NVeiDxoDcAzhhDbQWdKuuAyqyr67uYfY5qeeudoKYyJcjvfE0c1iMLpEQAlZDK_HjoChBEORcTcvbsCD-75y2lJhqsrW0cTWoqq0YTXU3SHvdewEZto8AEaQMKHnGozQQEkeF7rOFOJF7P_LX2LV7JbtxIl8RZPvjNNF6F6VHy_DJTVoJJNbIRRm47v8fXBBej60_76XZmxG_FtgZBevVgINq_lnYf2nb_2RybxyzRxfC4pRvTh6Og8mZy5fcgYIa4Yq3eXdDVAVxrFJWrJqfjdPSuZbFDuq6VfiXOAd_bNqNHMLN_jiTtJlVJnS-gk9Ejot8X-kwG-UPDoAQZIfyBqMSXIqyL-qFfVR8dIX9Dps"

      @sign_in_body %Schema{
        type: :object,
        title: "Sign in body",
        properties: %{
          username: %Schema{
            type: :string,
            description: "Required on Resource Owner Flow",
            example: "admin"
          },
          password: %Schema{
            type: :string,
            description: "Required on Resource Owner Flow",
            example: "admin"
          },
          client_id: %Schema{
            type: :string,
            description: "Application Client ID",
            required: true,
            example: @client_id
          },
          client_assertion: %Schema{
            type: :string,
            description: "Required while using keys",
            example: @client_assertion
          },
          client_assertion_type: %Schema{
            type: :string,
            description: "Required while using keys",
            example: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
          },
          client_secret: %Schema{
            type: :string,
            description: "Only used when we don't have access to the keys",
            example: @client_secret
          },
          grant_type: %Schema{
            type: :string,
            description: "Represent the authentication flow to be used",
            example: "password"
          },
          scope: %Schema{
            type: :string,
            description: "Represent the scopes an subject is requesting",
            example: "admin:read admin:write"
          }
        }
      }

      ############
      # Responses
      ############

      @access_token "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMDc5NzU2NywiaWF0IjoxNjAwNzkwMzY3LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpY210ODQ3NTg1ZHQ5YzgwMDAxcDEiLCJuYmYiOjE2MDA3OTAzNjcsInNjb3BlIjoiYWRtaW46cmVhZCBhZG1pbjp3cml0ZSIsInN1YiI6IjdmNWViOWRjLWI1NTAtNDU4Ni05MWRjLTNjNzAxZWIzYjliYyIsInR5cCI6IkJlYXJlciJ9.LWniDC38j2kW8ER8kgDnVVJO0eOXWGNq0KqXooMl-5s"
      @refresh_token "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdGkiOiIyb3JpY210ODQ3NTg1ZHQ5YzgwMDAxcDEiLCJhdWQiOiIyZTQ1NWJiMS0wNjA0LTQ4MTItOTc1Ni0zNmY3YWIyM2I4ZDkiLCJhenAiOiJhZG1pbiIsImV4cCI6MTYwMzM4MjM2NywiaWF0IjoxNjAwNzkwMzY3LCJpc3MiOiJXYXRjaGVyRXgiLCJqdGkiOiIyb3JpY210OG5vbjRkZHQ5YzgwMDAxcTEiLCJuYmYiOjE2MDA3OTAzNjcsInR5cCI6IkJlYXJlciJ9.U010q6KUB04K8rIU9rVnW_AOI1q5XSXSGIYdL1moaOA"

      @sign_in_response %Schema{
        type: :object,
        title: "Sign in response",
        properties: %{
          access_token: %Schema{
            type: :string,
            description: "The access token that should be used on API",
            example: @access_token
          },
          refresh_token: %Schema{
            type: :string,
            description: "The refresh token that should be used to get a new access_token",
            example: @refresh_token
          },
          expires_in: %Schema{
            type: :integer,
            description: "When the access_token will be expired",
            example: 7_200_000
          },
          token_type: %Schema{
            type: :string,
            description: "The type of the access_token",
            example: "Bearer"
          }
        }
      }

      swagger_path :sign_in do
        post("/api/v1/auth/protocol/openid-connect/token")
        summary("Sign in the identity")

        parameters do
          attributes(:body, @sign_in_body, "Request Body")
        end

        response(200, "SUCCESS", @sign_in_response)
      end
    end
  end
end
