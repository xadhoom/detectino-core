defmodule DtWeb.PartitionSensorView do
  use DtWeb.CrudMacroView
  use DtWeb.Web, :view

  @model :partition_sensor

  def render(_, %{partition_sensor: item}) do
    item
  end

end
