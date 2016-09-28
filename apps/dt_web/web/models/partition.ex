defmodule DtWeb.Partition do
  use DtWeb.Web, :model

  @derive {Poison.Encoder, only: [:id, :name, :entry_delay, :exit_delay]}
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
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :entry_delay, :exit_delay])
    |> validate_required([:name, :entry_delay, :exit_delay])
    |> unique_constraint(:name)
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :entry_delay, :exit_delay])
    |> validate_required([:name, :entry_delay, :exit_delay])
    |> unique_constraint(:name)
  end

end
