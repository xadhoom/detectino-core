defmodule DtCtx.Repo do
  @moduledoc false
  use Ecto.Repo, otp_app: :detectino, adapter: Ecto.Adapters.Postgres
end
