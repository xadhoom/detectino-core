defmodule DtCtx.Outputs.EventLogType do
  @moduledoc false
  @behaviour Ecto.Type

  alias DtCore.ArmEv
  alias DtCore.DetectorEv
  alias DtCore.DetectorExitEv
  alias DtCore.DetectorEntryEv
  alias DtCore.PartitionEv
  alias DtCore.ExitTimerEv

  def type, do: :json

  def cast(v = %ArmEv{}), do: {:ok, v}
  def cast(v = %DetectorEv{}), do: {:ok, v}
  def cast(v = %DetectorEntryEv{}), do: {:ok, v}
  def cast(v = %DetectorExitEv{}), do: {:ok, v}
  def cast(v = %PartitionEv{}), do: {:ok, v}
  def cast(v = %ExitTimerEv{}), do: {:ok, v}
  def cast(_), do: :error

  def load({:ok, json}), do: {:ok, json}
  def load(value), do: load(Poison.decode(value))

  def dump(ev = %ArmEv{}), do: Poison.encode(ev)
  def dump(ev = %DetectorEv{}), do: Poison.encode(ev)
  def dump(ev = %DetectorEntryEv{}), do: Poison.encode(ev)
  def dump(ev = %DetectorExitEv{}), do: Poison.encode(ev)
  def dump(ev = %PartitionEv{}), do: Poison.encode(ev)
  def dump(ev = %ExitTimerEv{}), do: Poison.encode(ev)
  def dump(_), do: :error

end

defmodule DtCtx.Outputs.EventLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "eventlogs" do
    field :type, :string
    field :acked, :boolean
    field :operation, :string
    field :details, DtCtx.Outputs.EventLogType

    timestamps()
  end

  @required_fields ~w(type operation details)
  @validate_required Enum.map(@required_fields, fn(x) -> String.to_atom(x) end)
  @source_types ["arm", "exit_timer", "alarm", "disarm",
    "detector_exit", "detector_entry"]

  def create_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields)
    |> validate_required(@validate_required)
    |> validate_inclusion(:type, @source_types)
  end

  def update_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields)
    |> validate_required(@validate_required)
    |> validate_inclusion(:type, @source_types)
  end

  def ack(struct) do
    struct
    |> cast(%{acked: true}, [:acked])
  end

end
