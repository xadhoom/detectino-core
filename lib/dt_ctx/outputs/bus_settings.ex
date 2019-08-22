defmodule DtCtx.Outputs.BusSettings do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @derive Jason.Encoder
  embedded_schema do
    field(:address, :string)
    field(:port, :integer)
    field(:type, :string)
    # on time in monostable mode
    field(:mono_ontime, :integer)
    # off time in monostable mode (pause time)
    field(:mono_offtime, :integer)
  end

  @required_fields [:address, :port, :type]
  @optional_fields [:mono_ontime, :mono_offtime]
  @types ["monostable", "bistable"]

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, @types)
    |> validate_timers
  end

  defp validate_timers(changeset) do
    case get_field(changeset, :type) do
      "bistable" ->
        changeset

      "monostable" ->
        validate_required(changeset, [:mono_ontime])

      _ ->
        add_error(changeset, :mono_ontime, "Can't be blank")
    end
  end
end
