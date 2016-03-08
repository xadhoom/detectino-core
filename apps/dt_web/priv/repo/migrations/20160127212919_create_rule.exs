defmodule DtWeb.Repo.Migrations.CreateRule do
  use Ecto.Migration

  def change do
    create table(:rules) do
      add :name, :string
      add :expression, :string
      add :continue, :boolean, default: false
      add :priority, :integer
      add :enabled, :boolean, default: false
      add :scenario_id, references(:scenarios)

      timestamps
    end

  end
end
