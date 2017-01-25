defmodule DtBus.Event do
  @moduledoc """
  Detectino event structure.

  All events from bus will be mapped to this struct
  and forwarded to all registered listeners (see DtBus.Can)
  """

  defstruct address: nil,
    port: nil,
    type: nil,
    subtype: nil,
    value: nil

end
