defmodule DtWeb.Repo.Migrations.CreateSensorTypes do
  use Ecto.Migration

  def change do
    create table(:sensor_types) do
      add :type, :string

      timestamps
    end

  end
end
