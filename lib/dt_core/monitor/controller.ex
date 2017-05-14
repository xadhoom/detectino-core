defmodule DtCore.Monitor.Controller do
  @moduledoc """
  Controller responsible of starting/stopping sensor detectors,
  via the Sensor Supervisor.
  Also receives messages from the Bus, normalize them and
  routes to the relevant worker, by looking into the address, port tuple.

  Performs also autodiscovery, by creating new sensors records
  into the Repo and starting the worker, if needed.
  """
  use GenServer

  require Logger

end
