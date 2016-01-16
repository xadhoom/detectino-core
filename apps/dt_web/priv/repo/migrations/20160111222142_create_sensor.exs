defmodule DtWeb.Repo.Migrations.CreateSensor do
  use Ecto.Migration

  def change do
    create table(:sensors) do
      add :address, :string
      add :port, :integer
      add :name, :string
      add :configured, :boolean, default: false

      timestamps
    end
    create index(:sensors, [:address, :port], unique: true, name: :address_port_idx)
    create index(:sensors, [:configured])

  end
end
