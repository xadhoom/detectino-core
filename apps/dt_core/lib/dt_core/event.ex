defmodule DtCore.EvRegistry do
  @moduledoc """
  Registry used to send event from sensors (via sensor server)
  to output workers (each one subscribes to different keys)
  """
  def registry do
    :registry_events
  end
end

defmodule DtCore.Event do
  @moduledoc """
  Event struct for DtCore events (from bus)
  """

  defstruct address: nil,
    port: nil,
    type: nil,
    subtype: nil,
    value: nil,
    delayed: false

end

defmodule DtCore.SensorEv do
  @moduledoc """
    type values:
      :reading
      :alarm
      :short
      :standby
      :fault
      :tamper
  """
  defstruct type: nil,
    delayed: false,
    address: nil,
    port: nil,
    urgent: false
end

defmodule DtCore.PartitionEv do
  @moduledoc """
    type values:
      :alarm
  """
  defstruct name: nil,
    delayed: false,
    type: nil
end
