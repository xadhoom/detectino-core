defmodule DtWeb.BusSettings do
  use DtWeb.Web, :model

  embedded_schema do
    field :address, :string
    field :port, :integer
    field :type, :string
    field :mono_ontime, :integer # on time in monostable mode
    field :mono_offtime, :integer # off time in monostable mode (pause time)
  end

  @required_fields ~w(address port type)
  @optional_fields ~w(mono_ontime mono_offtime)
  @validate_required Enum.map(@required_fields, fn(x) -> String.to_atom(x) end)
  @types ["monostable", "bistable"]

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required(@validate_required)
    |> validate_inclusion(:type, @types)
  end

end
