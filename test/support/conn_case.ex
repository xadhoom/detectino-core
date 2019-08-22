defmodule DtWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  imports other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      alias DtCtx.Repo
      import Ecto.Schema
      import Ecto.Query, only: [from: 2, first: 1]

      import DtWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint DtWeb.Endpoint
    end
  end

  setup tags do
    unless tags[:async] do
      :ok = Sandbox.checkout(DtCtx.Repo)
      Sandbox.mode(DtCtx.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
