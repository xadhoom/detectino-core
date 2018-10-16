defmodule DtWeb.UserView do
  use DtWeb.CrudMacroView
  use DtWeb.Web, :view

  @model :user

  def render("check_pin.json", %{expire: v}) do
    %{expire: v}
  end
end
