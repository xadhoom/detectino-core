defmodule DtCore.Event do
  @moduledoc """
  Event struct for DtCore events
  """

  defstruct address: nil,
    port: nil,
    type: nil,
    subtype: nil,
    value: nil

end
