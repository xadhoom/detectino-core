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
      add :enabled, :boolean, default: false

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
      add :type, :string
      add :enabled, :boolean, default: false
      timestamps()
    end

    # Holds all the event types handled by the application
    create table(:events) do
      add :name, :string
      timestamps()
    end

    create table(:events_outputs) do
      add :event_id, references(:events, on_delete: :delete_all, on_update: :update_all)
      add :output_id, references(:outputs, on_delete: :delete_all, on_update: :update_all)
      timestamps()
    end

  end
end
