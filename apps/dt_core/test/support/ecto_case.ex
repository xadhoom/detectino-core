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
      alias DtWeb.Repo
      import Ecto.Model
      import Ecto.Query, only: [from: 2]
      import DtCore.EctoCase
    end
  end

  setup tags do
    unless tags[:async] do
      Ecto.Adapters.SQL.restart_test_transaction(DtWeb.Repo, [])
    end
    
    :ok
  end
end
