defmodule DtWeb.GuardianHooks do
  @moduledoc """
  Adds additional verifications into Guardian JWT chain
  """
  use Guardian.Hooks

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
end
