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

  def on_verify(claims, jwt) do
    case TokenServer.get(jwt) do
      {:ok, _} ->
        {:ok, {claims, jwt}}

      _ ->
        {:error, :token_not_found}
    end
  end

  def after_encode_and_sign(resource, type, claims, jwt) do
    expiry = claims["exp"] - claims["iat"]

    case TokenServer.put(jwt, expiry) do
      {:ok, _} ->
        {:ok, {resource, type, claims, jwt}}

      _ ->
        {:error, :token_storage_failure}
    end
  end

  def on_revoke(claims, jwt) do
    case TokenServer.delete(jwt) do
      :ok ->
        {:ok, {claims, jwt}}

      _ ->
        {:error, :token_delete_failure}
    end
  end

  def subject_for_token(user = %User{}, _claims), do: {:ok, "User:#{user.id}"}
  def subject_for_token(_, _claims), do: {:error, "Unknown resource type"}

  def resource_from_claims("User:" <> id), do: {:ok, Repo.get(User, String.to_integer(id))}
  def resource_from_claims(_claims), do: {:error, "Unknown resource type"}
end
