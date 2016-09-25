defmodule DtWeb.SensorView do
  use DtWeb.CrudMacroView
  use DtWeb.Web, :view

  @model :sensor

  def render(_, %{sensor: item}) do
	item
  end

end
