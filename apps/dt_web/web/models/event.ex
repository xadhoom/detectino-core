defmodule DtWeb.Event.PartitionEvConf do
  defstruct name: nil,
    type: nil
end

defmodule DtWeb.Event.SensorEvConf do
  defstruct name: nil,
    address: nil,
    port: nil,
    type: nil
end

defmodule DtWeb.Event do
  use DtWeb.Web, :model

  alias DtWeb.Event.SensorEvConf
  alias DtWeb.Event.PartitionEvConf

  @derive {Poison.Encoder, only: [:id, :name, :description, :source]}
  schema "events" do
    field :name, :string
    field :description, :string
    field :source, :string
    field :source_config, :string

    timestamps

    many_to_many :outputs, DtWeb.Output, join_through: DtWeb.EventOutput
  end

  @optional_fields ~w(description)
  @required_fields ~w(name source source_config)
  @validate_required Enum.map(@required_fields, fn(x) -> String.to_atom(x) end)
  @source_types ["sensor", "partition"]

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required(@validate_required)
    |> validate_inclusion(:source, @source_types)
    |> check_config
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required(@validate_required)
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
      _ ->
        add_error(changeset, :source_config, "invalid")
    end
  end

  defp cast_config(changeset, change) do
    case fetch_field(changeset, :source) do
      :error ->
        add_error(changeset, :source, "invalid")
      {_, "sensor"} ->
        ret = Poison.decode(change, as: %SensorEvConf{})
        validate_config(changeset, ret)
      {_, "partition"} ->
        ret = Poison.decode(change, as: %PartitionEvConf{})
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

  defp validate_config(changeset, {:ok,  %SensorEvConf{port: nil}}) do
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
end
