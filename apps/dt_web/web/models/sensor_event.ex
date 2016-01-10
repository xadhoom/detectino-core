defmodule DtWeb.SensorEvent do
  use DtWeb.Web, :model

  schema "sensor_events" do
    field :uuid, :string
    field :type, :string
    field :subtype, :string
    field :value, :string

    timestamps
  end

  @required_fields ~w(type subtype value)
  @optional_fields ~w()

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> add_uuid
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  defp add_uuid(changeset) do
    changeset
    |> Ecto.Changeset.put_change(:uuid, UUID.uuid4())
  end

end
