defmodule DtCtx.Outputs.Event.ArmEvConf do
  @moduledoc false
  defstruct name: nil,
            initiator: nil
end

defmodule DtCtx.Outputs.Event.PartitionEvConf do
  @moduledoc false
  defstruct name: nil,
            type: nil
end

defmodule DtCtx.Outputs.Event.SensorEvConf do
  @moduledoc false
  defstruct name: nil,
            address: nil,
            port: nil,
            type: nil
end

defmodule DtCtx.Outputs.Event do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias DtCtx.Outputs.Event.ArmEvConf
  alias DtCtx.Outputs.Event.SensorEvConf
  alias DtCtx.Outputs.Event.PartitionEvConf
  alias DtLib.Json

  @derive {Jason.Encoder, only: [:id, :name, :description, :source]}
  schema "events" do
    field(:name, :string)
    field(:description, :string)
    field(:source, :string)
    field(:source_config, :string)

    timestamps()

    many_to_many(:outputs, DtCtx.Outputs.Output, join_through: DtCtx.Outputs.EventOutput)
  end

  @optional_fields [:description]
  @required_fields [:name, :source, :source_config]
  @source_types ["sensor", "partition", "arming"]

  def create_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:source, @source_types)
    |> check_config
  end

  def update_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:source, @source_types)
    |> check_config
  end

  defp check_config(changeset) do
    case fetch_field(changeset, :source_config) do
      :error ->
        add_error(changeset, :source_config, "invalid")

      {_, field} when is_nil(field) ->
        add_error(changeset, :source_config, "invalid")

      {_, field} ->
        cast_config(changeset, field)
    end
  end

  defp cast_config(changeset, change) do
    case fetch_field(changeset, :source) do
      :error ->
        add_error(changeset, :source, "invalid")

      {_, "sensor"} ->
        ret = Json.decode_as(change, SensorEvConf)
        validate_config(changeset, ret)

      {_, "partition"} ->
        ret = Json.decode_as(change, PartitionEvConf)
        validate_config(changeset, ret)

      {_, "arming"} ->
        ret = Json.decode_as(change, ArmEvConf)
        validate_config(changeset, ret)

      _ ->
        add_error(changeset, :source, "invalid")
    end
  end

  defp validate_config(changeset, {:error, _}) do
    add_error(changeset, :source_config, "format, cannot parse")
  end

  defp validate_config(changeset, {:ok, %SensorEvConf{address: nil}}) do
    add_error(changeset, :source_config, "invalid sensor config format: address")
  end

  defp validate_config(changeset, {:ok, %SensorEvConf{port: nil}}) do
    add_error(changeset, :source_config, "invalid sensor config format: port")
  end

  defp validate_config(changeset, {:ok, %SensorEvConf{type: nil}}) do
    add_error(changeset, :source_config, "invalid sensor config format: type")
  end

  defp validate_config(changeset, {:ok, %SensorEvConf{}}) do
    changeset
  end

  defp validate_config(changeset, {:ok, %PartitionEvConf{name: nil}}) do
    add_error(changeset, :source_config, "invalid partition config format: name")
  end

  defp validate_config(changeset, {:ok, %PartitionEvConf{type: nil}}) do
    add_error(changeset, :source_config, "invalid partition config format: type")
  end

  defp validate_config(changeset, {:ok, %PartitionEvConf{}}) do
    changeset
  end

  defp validate_config(changeset, {:ok, %ArmEvConf{name: nil}}) do
    add_error(changeset, :source_config, "invalid arming config format: name")
  end

  defp validate_config(changeset, {:ok, %ArmEvConf{}}) do
    changeset
  end
end
