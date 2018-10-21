defmodule DtWeb.GuardianSerializer do
  @moduledoc false
  @behaviour Guardian.Serializer

  alias DtCtx.Repo
  alias DtCtx.Accounts.User

  def for_token(user = %User{}), do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("User:" <> id), do: {:ok, Repo.get(User, String.to_integer(id))}
  def from_token(_thing), do: {:error, "Unknown resource type"}
end
