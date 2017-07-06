defmodule DtCtx.Repo.Migrations.CreateEventlogs do
  use Ecto.Migration

  def change do

    # Log all events
    create table(:eventlogs) do
      add :type, :string
      add :acked, :boolean, default: false
      add :operation, :string
      add :details, :map

      timestamps()
    end

    # will play with trigrams when needed, if needed.
    # the index is not correct since a ref to a json attr must be given
    # or the field must be text
    #execute "CREATE EXTENSION pg_trgm;"
    #execute "CREATE INDEX details_trgm_gin_idx ON eventlogs USING gin (details gin_trgm_ops);"
    execute "CREATE INDEX details_gin_idx ON eventlogs USING gin (details);"

    create index(:eventlogs, [:type])
  end

end
