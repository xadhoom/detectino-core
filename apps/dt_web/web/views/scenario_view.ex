defmodule DtWeb.ScenarioView do
  use DtWeb.CrudMacroView
  use DtWeb.Web, :view

  @model :scenario

  def render(_, %{scenario: item}) do
    item
  end

end
