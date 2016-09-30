defmodule DtWeb.PartitionScenarioView do
  use DtWeb.CrudMacroView
  use DtWeb.Web, :view

  @model :partition_scenario

  def render(_, %{partition_scenario: item}) do
    item
  end

end
