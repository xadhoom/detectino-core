defmodule DtWeb.SensorView do
  use DtWeb.Web, :view

  def render("index.json", %{items: items}) do
    render_many(items, __MODULE__, "sensor.json")
  end

  def render("show.json", %{item: item}) do
    render_one(item, __MODULE__, "sensor.json")
  end

  def render("create.json", %{item: item}) do
    render_one(item, __MODULE__, "sensor.json")
  end

  def render("update.json", %{item: item}) do
    render_one(item, __MODULE__, "sensor.json")
  end

  def render("sensor.json", %{sensor: item}) do
    EctoRenderer.render item
  end

end
