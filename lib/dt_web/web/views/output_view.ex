defmodule DtWeb.OutputView do
  use DtWeb.CrudMacroView
  use DtWeb.Web, :view

  @model :output

  def render(_, %{output: item}) do
    item
  end
end
