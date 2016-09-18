defmodule DtWeb.Repo.Migrations.CreateAlarmStruct do
  use Ecto.Migration

  def change do
    create table(:partitions) do
      add :name, :string
      add :entry_delay, :integer
      add :exit_delay, :integer

      timestamps()
    end

    create table(:sensors) do
      add :address, :string
      add :port, :integer
      add :name, :string
      add :enabled, :boolean, default: false

      timestamps()
    end
    create index(:sensors, [:address, :port], unique: true, name: :address_port_idx)
    create index(:sensors, [:enabled])

    create table(:partitions_sensors) do
      add :partition_id, references(:partitions, on_delete: :delete_all, on_update: :update_all)
      add :sensor_id, references(:sensors, on_delete: :delete_all, on_update: :update_all)

      timestamps()
    end

    create table(:scenarios) do
      add :name, :string
      add :enabled, :boolean, default: false
      timestamps()
    end
    create index(:scenarios, [:name], unique: true, name: :name_idx)

    create table(:partitions_scenarios) do
      add :partition_id, references(:partitions, on_delete: :delete_all, on_update: :update_all)
      add :scenario_id, references(:scenarios, on_delete: :delete_all, on_update: :update_all)
      add :mode, :string

      timestamps()
    end

  end
end
