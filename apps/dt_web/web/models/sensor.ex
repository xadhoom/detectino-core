defmodule DtWeb.Sensor do
  use DtWeb.Web, :model

  # @derive {Poison.Encoder, only: [:id, :address, :port, :name, :enabled]}
  schema "sensors" do
    field :address, :string
    field :port, :integer
    field :name, :string
    field :enabled, :boolean, default: false

    timestamps()

    many_to_many :partitions, DtWeb.Partition, join_through: DtWeb.PartitionSensor, on_replace: :delete
  end

  @required_fields ~w(name address port)
  @optional_fields ~w(enabled)
  @validate_required Enum.map(@required_fields, fn(x) -> String.to_atom(x) end)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required(@validate_required)
    |> unique_constraint(:address, name: :sensors_address_port_index)
    |> unique_constraint(:port, name: :sensors_address_port_index)
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required(@validate_required)
    |> unique_constraint(:address, name: :sensors_address_port_index)
    |> unique_constraint(:port, name: :sensors_address_port_index)
  end

end
