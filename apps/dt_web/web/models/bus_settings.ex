defmodule DtWeb.BusSettings do
  use DtWeb.Web, :model

  embedded_schema do
    field :address
    field :port
    field :payload # still does not know what I need
  end

  @required_fields ~w(address)
  @optional_fields ~w(port, payload)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

end