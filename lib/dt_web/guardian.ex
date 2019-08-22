defmodule DtWeb.Guardian do
  @moduledoc """
  Adds additional verifications into Guardian JWT chain
  """
  # use Guardian.Hooks
  use Guardian, otp_app: :detectino

  alias DtCtx.Accounts.User
  alias DtCtx.Repo
  alias DtWeb.TokenServer

  require Logger

  def on_verify(claims, jwt, _opts) do
    case TokenServer.get(jwt) do
      {:ok, _} ->
        {:ok, claims}

      _ ->
        {:error, :token_not_found}
    end
  end

  def after_encode_and_sign(_resource, claims, jwt, _opts) do
    expiry = claims["exp"] - claims["iat"]

    case TokenServer.put(jwt, expiry) do
      {:ok, _} ->
        {:ok, jwt}

      _ ->
        {:error, :token_storage_failure}
    end
  end

  def on_revoke(claims, jwt, _opts) do
    case TokenServer.delete(jwt) do
      :ok ->
        {:ok, claims}

      _ ->
        {:error, :token_delete_failure}
    end
  end

  def on_refresh({old_token, _old_claims} = old, {new_token, new_claims} = new, _opts) do
    expiry = new_claims["exp"] - new_claims["iat"]

    with :ok <- TokenServer.delete(old_token),
         {:ok, _} <- TokenServer.put(new_token, expiry) do
      {:ok, old, new}
    else
      _ -> {:error, :token_refresh_failure}
    end
  end

  def subject_for_token(%User{} = user, _claims), do: {:ok, "User:#{user.id}"}
  def subject_for_token(_, _claims), do: {:error, "Unknown resource type"}

  def resource_from_claims("User:" <> id), do: {:ok, Repo.get(User, String.to_integer(id))}
  def resource_from_claims(_claims), do: {:error, "Unknown resource type"}
end

defmodule DtWeb.Guardian.AuthErrorHandler do
  @moduledoc false
  alias DtWeb.TokenServer
  alias Plug.Conn
  alias Plug.Conn.Status

  def auth_error(conn, {:unauthenticated, _reason}, _opts) do
    token =
      conn
      |> Conn.get_req_header("authorization")
      |> Enum.at(0)

    case token do
      nil -> nil
      v -> TokenServer.expire({:token, v})
    end

    Conn.send_resp(conn, 401, Status.reason_phrase(401))
  end

  def auth_error(conn, {_failure_type, _reason}, _opts) do
    Conn.send_resp(conn, 401, Status.reason_phrase(401))
  end
end
