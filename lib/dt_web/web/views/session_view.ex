defmodule DtWeb.SessionView do
  @moduledoc false
  use DtWeb.Web, :view

  def render("logged_in.json", %{token: token}) do
    %{token: token}
  end
end
