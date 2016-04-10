defmodule DtWeb.Repo.Migrations.AddDefaultUser do
  use Ecto.Migration

  def up do
    ts = Ecto.DateTime.utc
    password = Comeonin.Bcrypt.hashpwsalt("password")
    execute "INSERT INTO users (name, username, encrypted_password, role,
      inserted_at, updated_at) VALUES ('admin', 'admin@local',
      '#{password}', 'admin', '#{ts}', '#{ts}');"
  end

  def down do
    execute "DELETE from users where username='admin@local';"
  end
end
