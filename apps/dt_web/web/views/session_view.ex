defmodule DtWeb.SessionView do
  use DtWeb.Web, :view

  def render("logged_in.json", %{token: token}) do
    %{token: token}
  end

  def render("new.json", assigns) do
    Poison.encode!(assigns.users)
  end

end
