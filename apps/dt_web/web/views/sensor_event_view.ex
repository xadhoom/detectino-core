defmodule DtWeb.SensorEventView do
  use DtWeb.Web, :view

  def render("index.json", %{sensor_events: sensor_events}) do
    %{data: render_many(sensor_events, DtWeb.SensorEventView, "sensor_event.json")}
  end

  def render("show.json", %{sensor_event: sensor_event}) do
    %{data: render_one(sensor_event, DtWeb.SensorEventView, "sensor_event.json")}
  end

  def render("sensor_event.json", %{sensor_event: sensor_event}) do
    %{id: sensor_event.id,
      uuid: sensor_event.uuid,
      type: sensor_event.type,
      subtype: sensor_event.subtype,
      value: sensor_event.value}
  end
end
