defmodule DtWeb.Repo.Migrations.CreateSensorEvent do
  use Ecto.Migration

  def change do
    create table(:sensor_events) do
      add :uuid, :string, null: false
      add :type, :string
      add :subtype, :string
      add :value, :string

      timestamps
    end

    create index(:sensor_events, [:uuid], unique: true)

  end
end
