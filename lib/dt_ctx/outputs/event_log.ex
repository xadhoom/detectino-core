defmodule DtCtx.Outputs.EventLogType do
  @moduledoc false
  @behaviour Ecto.Type

  alias DtCore.ArmEv
  alias DtCore.DetectorEv
  alias DtCore.DetectorExitEv
  alias DtCore.DetectorEntryEv
  alias DtCore.PartitionEv
  alias DtCore.ExitTimerEv

  def type, do: :jsonb

  def cast(v = %ArmEv{}), do: {:ok, v}
  def cast(v = %DetectorEv{}), do: {:ok, v}
  def cast(v = %DetectorEntryEv{}), do: {:ok, v}
  def cast(v = %DetectorExitEv{}), do: {:ok, v}
  def cast(v = %PartitionEv{}), do: {:ok, v}
  def cast(v = %ExitTimerEv{}), do: {:ok, v}
  def cast(_), do: :error

  def load({:ok, json}), do: {:ok, json}
  def load(value), do: {:ok, value}

  def dump(ev = %ArmEv{}), do: encode(ev, :arm)
  def dump(ev = %DetectorEv{}), do: encode(ev, :detector)
  def dump(ev = %DetectorEntryEv{}), do: encode(ev, :detector_entry)
  def dump(ev = %DetectorExitEv{}), do: encode(ev, :detector_exit)
  def dump(ev = %PartitionEv{}), do: encode(ev, :partition)
  def dump(ev = %ExitTimerEv{}), do: encode(ev, :exit_timer)
  def dump(_), do: :error

  defp encode(ev, source) when is_atom(source) do
    data = %{"source" => Atom.to_string(source),
      "ev" => Map.from_struct(ev)}
    {:ok, data}
  end

end

defmodule DtCtx.Outputs.EventLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "eventlogs" do
    field :type, :string
    field :acked, :boolean
    field :operation, :string
    field :correlation_id, :string
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
    |> add_id
  end

  def update_changeset(_model, _params \\ %{}) do
    raise Ecto.ChangeError, message: "Cannot update an event log"
  end

  def ack(struct) do
    struct
    |> cast(%{acked: true}, [:acked])
  end

  defp add_id(changeset) do
    id = changeset
    |> get_change(:details)
    |> Map.get(:id)

    put_change(changeset, :correlation_id, id)
  end

end
