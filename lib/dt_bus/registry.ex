defmodule DtBus.ActionRegistry do
  @moduledoc """
  Registry used to dispatch actions from dt_core to dt_bus, in order
  to send commands to CanBus devices

  TODO: listeners not yet implemented
  """
  def registry do
    :bus_actions
  end
end

defmodule DtBus.OutputAction do
  @moduledoc """
  Struct used to encapsulate commands sent to the bus
  and dispatched via DtBus.ActionRegistry
  """
  defstruct command: nil,
            address: nil,
            port: nil
end
