defmodule DtWeb.OutputView do
  @moduledoc false
  use DtWeb.CrudMacroView
  use DtWeb.Web, :view

  @model :output

  def render(_, %{output: item}) do
    item
  end
end
