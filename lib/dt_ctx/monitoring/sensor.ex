defmodule DtCtx.Monitoring.Sensor do
  use Ecto.Schema
  import Ecto.Changeset

  # @derive {Poison.Encoder, only: [:id, :address, :port, :name, :enabled]}
  schema "sensors" do
    field :address, :string
    field :port, :integer
    field :name, :string
    field :balance, :string # type of balance, one of NC, NO, EOL, DEOL, TEOL
    field :th1, :integer # these are the thresholds for various balance modes
    field :th2, :integer
    field :th3, :integer
    field :th4, :integer
    field :enabled, :boolean, default: false
    field :tamp24h, :boolean, default: false
    field :full24h, :boolean, default: false
    field :entry_delay, :boolean, default: false
    field :exit_delay, :boolean, default: false
    field :internal, :boolean, default: false

    timestamps()

    many_to_many :partitions, DtCtx.Monitoring.Partition,
      join_through: DtCtx.Monitoring.PartitionSensor, on_replace: :delete
  end

  @required_fields ~w(name address port)
  @optional_fields ~w(enabled balance th1 th2 th3 th4
    full24h tamp24h entry_delay exit_delay internal)
  @validate_required Enum.map(@required_fields, fn(x) -> String.to_atom(x) end)
  @balance_types ["NC", "NO", "EOL", "DEOL", "TEOL"]

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def create_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@validate_required)
    |> validate_inclusion(:balance, @balance_types)
    |> unique_constraint(:address, name: :sensors_address_port_index)
    |> unique_constraint(:port, name: :sensors_address_port_index)
  end

  def update_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@validate_required)
    |> validate_inclusion(:balance, @balance_types)
    |> unique_constraint(:address, name: :sensors_address_port_index)
    |> unique_constraint(:port, name: :sensors_address_port_index)
  end

end
