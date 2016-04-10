defmodule DtWeb.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :username, :string
      add :password, :string
      add :encrypted_password, :string
      add :role, :string

      timestamps
    end

  end
end
