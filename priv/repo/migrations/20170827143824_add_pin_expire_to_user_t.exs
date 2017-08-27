defmodule DtCtx.Repo.Migrations.AddPinExpireToUserT do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pin_expire, :integer, default: 60_000
    end
  end

end
