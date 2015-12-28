defmodule DtWeb.UserQuery do
  import Ecto.Query
  alias DtWeb.User

  def by_email(email) do
    from u in User, where: u.email == ^email
  end

end
