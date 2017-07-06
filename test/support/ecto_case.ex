defmodule DtCore.EctoCase do
  @moduledoc """
  If the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias DtCtx.Repo
      import Ecto.Schema
      import Ecto.Query, only: [from: 2]
    end
  end

  setup tags do
    unless tags[:async] do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(DtCtx.Repo)
      Ecto.Adapters.SQL.Sandbox.mode(DtCtx.Repo, {:shared, self()})
    end

    :ok
  end
end
