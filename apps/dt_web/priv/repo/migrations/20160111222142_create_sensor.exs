defmodule DtWeb.Repo.Migrations.CreateSensor do
  use Ecto.Migration

  def change do
    create table(:sensors) do
      add :address, :string
      add :name, :string
      add :type_id, references(:sensor_types)
      add :configured, :boolean, default: false

      timestamps
    end
    create index(:sensors, [:type_id])
    create index(:sensors, [:address], unique: true)
    create index(:sensors, [:configured])

  end
end
