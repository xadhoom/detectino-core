defmodule DtWeb.Repo.Migrations.CreateScenario do
  use Ecto.Migration

  def change do
    create table(:scenarios) do
      add :name, :string
      add :enabled, :boolean, default: false

      timestamps
    end

  end
end
