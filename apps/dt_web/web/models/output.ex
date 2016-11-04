defmodule DtWeb.Output do
  use DtWeb.Web, :model

  @derive {Poison.Encoder, only: [:id, :name, :type, :enabled]}
  schema "outputs" do
    field :name, :string
    field :type, :string
    field :enabled, :boolean
    embeds_one :bus_settings, DtWeb.BusSettings
    embeds_one :email_settings, DtWeb.EmailSettings

    timestamps

    many_to_many :events, DtWeb.Event, join_through: DtWeb.EventOutput
  end

  @required_fields ~w(name type enabled)
  @optional_fields ~w()
  @validate_required Enum.map(@required_fields, fn(x) -> String.to_atom(x) end)
  @valid_types ["bus", "email"]

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required(@validate_required)
    |> validate_inclusion(:enabled, [true, false])
    |> validate_inclusion(:type, @valid_types)
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required(@validate_required)
    |> validate_inclusion(:enabled, [true, false])
    |> validate_inclusion(:type, @valid_types)
  end

end
