defmodule DtWeb.ScenarioView do
  @moduledoc false
  use DtWeb.CrudMacroView
  use DtWeb.Web, :view

  @model :scenario

  def render("get_available.json", %{items: items}) do
    render_many(items, __MODULE__, "#{Atom.to_string(@model)}.json")
  end

  def render(_, %{scenario: item}) do
    item
  end
end
