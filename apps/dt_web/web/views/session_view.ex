defmodule DtWeb.SessionView do
  use DtWeb.Web, :view

  def render("new.json", assigns) do
    Poison.encode!(assigns.users)
  end

end
