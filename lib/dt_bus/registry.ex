defmodule DtBus.ActionRegistry do
  @moduledoc """
  Registry used to dispatch actions from dt_core to dt_bus, in order
  to send commands to CanBus devices
  """
  def registry do
    :bus_actions
  end
end
