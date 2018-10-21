defmodule DtWeb.PartitionView do
  @moduledoc false
  use DtWeb.CrudMacroView
  use DtWeb.Web, :view

  @model :partition

  def render(_, %{partition: item}) do
    item
  end
end
