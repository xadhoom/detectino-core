defmodule DtCtx.Monitoring.Partition do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Poison.Encoder,
           only: [
             :id,
             :name,
             :entry_delay,
             :exit_delay,
             :armed
           ]}
  schema "partitions" do
    field(:name, :string)
    field(:entry_delay, :integer)
    field(:exit_delay, :integer)
    field(:armed, :string)

    timestamps()

    many_to_many(
      :sensors,
      DtCtx.Monitoring.Sensor,
      join_through: DtCtx.Monitoring.PartitionSensor
    )

    many_to_many(
      :scenarios,
      DtCtx.Monitoring.Scenario,
      join_through: DtCtx.Monitoring.PartitionScenario
    )
  end

  @required_fields ~w(name entry_delay exit_delay)
  @optional_fields ~w(armed)
  @validate_required Enum.map(@required_fields, fn x -> String.to_atom(x) end)
  @valid_modes ["ARM", "ARMSTAY", "ARMSTAYIMMEDIATE", "DISARM"]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@validate_required)
    |> validate_inclusion(:armed, @valid_modes)
    |> unique_constraint(:name)
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@validate_required)
    |> validate_inclusion(:armed, @valid_modes)
    |> unique_constraint(:name)
  end

  def arm_op_from_mode(mode) do
    case mode do
      "ARM" -> :arm
      "ARMSTAY" -> :arm
      "ARMSTAYIMMEDIATE" -> :arm
      "DISARM" -> :disarm
    end
  end

  def arm(struct, mode) do
    struct
    |> cast(%{armed: mode}, [:armed])
    |> validate_inclusion(:armed, @valid_modes)
  end

  def disarm(struct) do
    struct
    |> cast(%{armed: "DISARM"}, [:armed])
  end

  def arm_mode_str_to_atom(mode) do
    case mode do
      "ARM" -> :normal
      "ARMSTAY" -> :stay
      "ARMSTAYIMMEDIATE" -> :immediate
      _ -> :error
    end
  end
end
