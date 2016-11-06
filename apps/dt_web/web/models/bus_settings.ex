defmodule DtWeb.BusSettings do
  use DtWeb.Web, :model

  embedded_schema do
    field :address
    field :port
    field :payload # I do not know what I really need here
  end

  @required_fields ~w(address)
  @optional_fields ~w(port payload)
  @validate_required Enum.map(@required_fields, fn(x) -> String.to_atom(x) end)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required(@validate_required)
  end

end
