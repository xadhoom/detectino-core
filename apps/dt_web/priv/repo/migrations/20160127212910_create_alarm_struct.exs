defmodule DtWeb.Repo.Migrations.CreateAlarmStruct do
  use Ecto.Migration

  def change do
    # Partitions are groups of Sensors (also called Zones).
    # They will get (d)activated, thus enabling events sent
    # by the sensors beloging to it.
    create table(:partitions) do
      add :name, :string
      add :entry_delay, :integer
      add :exit_delay, :integer
      add :armed, :string
      add :last_armed, :string

      timestamps()
    end
    create index(:partitions, [:name], unique: true)

    # Sensors are the basic item of an alarm system.
    # They will provide readings and send out events based
    # on their configuration.
    create table(:sensors) do
      add :address, :string
      add :port, :integer
      add :name, :string
      add :balance, :string
      add :th1, :integer
      add :th2, :integer
      add :th3, :integer
      add :th4, :integer
      add :enabled, :boolean, default: false
      add :full24h, :boolean, default: false
      add :tamp24h, :boolean, default: false
      add :entry_delay, :boolean, default: false
      add :exit_delay, :boolean, default: false

      timestamps()
    end
    create index(:sensors, [:address, :port], unique: true)
    create index(:sensors, [:enabled])

    create table(:partitions_sensors) do
      add :partition_id, references(:partitions, on_delete: :delete_all, on_update: :update_all)
      add :sensor_id, references(:sensors, on_delete: :delete_all, on_update: :update_all)

      timestamps()
    end

    # Scenarios are just a collection of areas, that allow to shortcut
    # area activation, with some extra attribute (total, partial, whatever)
    create table(:scenarios) do
      add :name, :string
      add :enabled, :boolean, default: false
      timestamps()
    end
    create index(:scenarios, [:name], unique: true)

    create table(:partitions_scenarios) do
      add :partition_id, references(:partitions, on_delete: :delete_all, on_update: :update_all)
      add :scenario_id, references(:scenarios, on_delete: :delete_all, on_update: :update_all)
      add :mode, :string

      timestamps()
    end

    # Ouputs are commands sent when a certain action is triggered by an event
    create table(:outputs) do
      add :name, :string
      add :description, :string
      add :type, :string
      add :enabled, :boolean, default: false
      add :bus_settings, :map
      add :email_settings, :map

      timestamps()
    end
    create index(:outputs, [:name], unique: true)

    # Events are the bridge between sensors and outputs
    create table(:events) do
      add :name, :string
      add :description, :string

      timestamps()
    end
    create index(:events, [:name], unique: true)

    create table(:events_outputs) do
      add :event_id, references(:events, on_delete: :delete_all, on_update: :update_all)
      add :output_id, references(:outputs, on_delete: :delete_all, on_update: :update_all)
      timestamps()
    end

  end
end
