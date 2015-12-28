defmodule DtWeb.Repo.Migrations.AddDefaultUser do
  use Ecto.Migration

  def up do
    ts = Ecto.DateTime.local
    password = Comeonin.Bcrypt.hashpwsalt("password")
    execute "INSERT INTO users (name, email, encrypted_password, inserted_at, updated_at) 
              VALUES ('admin', 'admin@local', '#{password}', '#{ts}', '#{ts}');"
  end

  def down do
    execute "DELETE from users where email='admin@local';"
  end
end
