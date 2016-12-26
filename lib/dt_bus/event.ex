defmodule DtBus.Event do
  @moduledoc """
  Detectino event structure
  """

  defstruct address: nil,
    port: nil,
    type: nil,
    subtype: nil,
    value: nil

end
