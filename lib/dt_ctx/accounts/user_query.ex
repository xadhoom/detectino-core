defmodule DtCtx.Accounts.UserQuery do
  import Ecto.Query
  alias DtCtx.Accounts.User

  def by_username(username) do
    from(u in User, where: u.username == ^username)
  end
end
