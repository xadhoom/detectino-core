defmodule DtCore.OutputsRegistry do
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
  Event struct for DtCore events (from bus).
  DtBus.Event is normalize to DtCore.Event and forwarded to sensor workers
  """

  defstruct address: nil,
    port: nil,
    type: nil,
    subtype: nil,
    value: nil
end

defmodule DtCore.DetectorEv do
  @moduledoc """
    Used to format output from Detector Workers.
    Is listened to by Partition Workers and via DtCore.OutputsRegistry.

    type values:
      :realtime
      :alarm
      :short
      :idle
      :fault
      :tamper
  """
  defstruct type: nil,
    address: nil,
    port: nil
end

defmodule DtCore.DetectorExitEv do
  defstruct address: nil,
    port: nil
end

defmodule DtCore.DetectorEntryEv do
  defstruct address: nil,
    port: nil
end

defmodule DtCore.PartitionEv do
  @moduledoc """
    Used to format output from Partition Workers.
    Is listened to via DtCore.OutputsRegistry.

    name: the partition name, binary()
    type: alarm type, atom()

    type values: same as %DtCore.DetectorEv{} type field
  """
  defstruct name: nil,
    type: nil
end

defmodule DtCore.ArmEv do
  @moduledoc """
    Used notify about arming/disarming events from each Partition.

    name: the partition name, binary()
    partial: whether is a partial arming, boolean()

  """
  defstruct name: nil,
    partial: nil

end

defmodule DtCore.ExitTimerEv do
  @moduledoc """
    Used notify exit timer start/stop when a partition is armed.

    name: the partition name, binary()

  """
  defstruct name: nil

end
