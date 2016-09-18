defmodule DtWeb.Sensor do
  use DtWeb.Web, :model

  schema "sensors" do
    field :address, :string
    field :port, :integer
    field :name, :string
    field :enabled, :boolean, default: false

    timestamps()

    many_to_many :partitions, DtWeb.Partition, join_through: DtWeb.PartitionSensor
  end

  @required_fields ~w(address port)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:address, name: :address_port_idx)
    |> unique_constraint(:port, name: :address_port_idx)
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:address, name: :address_port_idx)
    |> unique_constraint(:port, name: :address_port_idx)
  end

end
