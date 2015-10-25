defmodule DtBus.Cansim do
  use GenServer
  use Bitwise

  alias DtBus.Canhelper, as: Canhelper

  require Logger

  @myid 66 # node id on canbus

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :detectino_sim)
  end

  #
  # GenServer Callbacks
  #
  def init(_) do
    :timer.send_interval(10000, :status)
    :can_router.attach()
    {:ok, nil}
  end

  def handle_call(value, _from, state) do
    Logger.debug "Got call message #{inspect value}"
    {:reply, nil, state}
  end

  def handle_cast(value, state) do
    Logger.debug "Got cast message #{inspect value}"
    {:noreply, state}
  end

  def handle_info({:can_frame, msgid, len, data, _intf, _ts}, state) do
    {:ok, src_node_id, dst_node_id, command, subcommand} = Canhelper.decode_msgid(msgid)

    if dst_node_id == @myid do
      Logger.info "Got command:#{command}, subcommand:#{subcommand} " <>
        "from id:#{src_node_id} to id:#{dst_node_id} " <>
        "datalen:#{inspect len} payload:#{inspect data}"
    end

    {:noreply, state}
  end

  def handle_info(:status, state) do
    Logger.debug "Sending can frame"
    msgid = Canhelper.build_msgid(@myid, 0, :event, :unsolicited)

    # send random analog reads...
    Enum.each(1..8, fn(index) ->
      val = Enum.random(1..1024) #random reading, for now
      msb = val >>> 8 |> band 0xff
      lsb = band val, 0xff
      payload = <<0,0,0,0,0,index,msb,lsb>>
      {:can_frame, msgid, 8, payload, 0, -1} |> :can_router.send
    end)

    # send random digital reads...
    Enum.each(1..3, fn(index) ->
      val = Enum.random(0..1) #random reading, for now
      payload = <<0,0,0,0,index,0,0,val>>
      {:can_frame, msgid, 8, payload, 0, -1} |> :can_router.send
    end)
    {:noreply, state}
  end

  def handle_info(value, state) do
    Logger.debug "Got info message #{inspect value}"
    {:noreply, state}
  end

end
