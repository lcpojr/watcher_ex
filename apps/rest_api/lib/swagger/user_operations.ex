defmodule RestAPI.Swagger.UserOperations do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use PhoenixSwagger

      alias PhoenixSwagger.Schema

      ###########
      # Requests
      ###########

      @create_request %Schema{
        type: :object,
        title: "User creation body",
        properties: %{
          username: %Schema{
            type: :string,
            description: "User email or nickname",
            required: true,
            example: "my_admin_username"
          },
          password: %Schema{
            type: :string,
            description: "User Password credential",
            required: true,
            example: "myPass@rd123"
          },
          scopes: %Schema{
            type: :array,
            description: "List of scopes",
            required: true,
            example: ["admin:read", "admin:write"]
          }
        }
      }

      ############
      # Responses
      ############

      @create_response %Schema{
        type: :object,
        title: "Sign in response",
        properties: %{
          id: %Schema{
            type: :string,
            description: "User identifier",
            example: "497ea1c2-a30e-4b86-8f3b-0c860b8e9e79"
          },
          username: %Schema{
            type: :string,
            description: "User email or nickname",
            example: "my_admin_username"
          },
          is_admin: %Schema{
            type: :boolean,
            description: "Represents if a user has access to admin api or not",
            example: true
          },
          status: %Schema{
            type: :string,
            description: "Represents if a user is active or not",
            example: "active"
          },
          inserted_at: %Schema{
            type: :string,
            description: "When the identity was created",
            example: "2020-11-29 13:29:06.947381"
          }
        }
      }

      swagger_path :create do
        post("/admin/v1/users/")
        summary("Creates a new user identity")
        security([%{Bearer: []}])

        parameters do
          attributes(:body, @create_request, "Request Body")
        end

        response(200, "SUCCESS", @create_response)
      end
    end
  end
end
