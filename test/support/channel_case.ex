defmodule DtWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  imports other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      use Phoenix.ChannelTest

      alias DtCtx.Repo
      import Ecto.Schema
      import Ecto.Query, only: [from: 2]


      # The default endpoint for testing
      @endpoint DtWeb.Endpoint
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
