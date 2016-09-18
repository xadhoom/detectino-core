defmodule DtWeb.Partition do
  use DtWeb.Web, :model

  schema "partitions" do
    field :name, :string
    field :entry_delay, :integer
    field :exit_delay, :integer

    timestamps()

    many_to_many :sensors, DtWeb.Sensor, join_through: DtWeb.PartitionSensor
    many_to_many :scenarios, DtWeb.Scenario, join_through: DtWeb.PartitionScenario
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :entry_delay, :exit_delay])
    |> validate_required([:name, :entry_delay, :exit_delay])
  end
end
