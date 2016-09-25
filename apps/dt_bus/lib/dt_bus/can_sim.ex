defmodule DtBus.CanSim do
  @moduledoc """
  Provide a CanBus simulator to aid in development and testing.
  """

  use GenServer
  use Bitwise

  alias DtBus.CanHelper, as: Canhelper

  require Logger

  #
  # Client APIs
  #
  def start_link(myid, sender_fn \\ &(:can_router.send &1)) when is_integer(myid) and myid > 0 and myid < 127 do
    GenServer.start_link(__MODULE__, {myid, sender_fn}, name: __MODULE__)
  end

  def autorun do
    GenServer.call(__MODULE__, {:autorun})
  end

  #
  # GenServer Callbacks
  #
  def init({myid, sender_fn}) do
    :can_router.attach()
    {:ok, %{myid: myid, sender_fn: sender_fn}}
  end

  def handle_call({:autorun}, _from, state) do
    :timer.send_interval(10000, :status)
    {:reply, :ok, state}
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
    case Canhelper.decode_msgid(msgid) do
      {:ok, src_node_id, dst_node_id, command, subcommand} ->
        if dst_node_id == state.myid do
          Logger.info "Got command:#{command}, subcommand:#{subcommand} " <>
            "from id:#{src_node_id} to id:#{dst_node_id} " <>
            "datalen:#{inspect len} payload:#{inspect data}"
          case command do
            :ping -> 
              handle_ping(state.myid, src_node_id, data, state.sender_fn)
            :read -> 
              handle_read(state.myid, subcommand, src_node_id, state.sender_fn)
            :readd -> 
              handle_readd(state.myid, subcommand, src_node_id, state.sender_fn)
            unh ->
              Logger.warn "Unhandled can command #{inspect unh}"
          end
        end
    _v -> nil
    end

    {:noreply, state}
  end

  def handle_info(:status, state) do
    Logger.debug "Sending can frame"
    msgid = Canhelper.build_msgid(state.myid, 0, :event, :unsolicited)

    # send random analog reads...
    Enum.each(1..8, fn(index) ->
      val = Enum.random(1..1024) #random reading, for now
      msb = val >>> 8 |> band(0xff)
      lsb = band val, 0xff
      payload = <<0,0,0,0,0,index,msb,lsb>>
      state.sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
    end)

    # send random digital reads...
    Enum.each(1..3, fn(index) ->
      val = Enum.random(0..1) #random reading, for now
      payload = <<0,0,0,0,index,0,0,val>>
      state.sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
    end)
    {:noreply, state}
  end

  def handle_info(value, state) do
    Logger.debug "Got info message #{inspect value}"
    {:noreply, state}
  end

  defp handle_ping(myid, src_node_id, data, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :pong, :reply)
    sender_fn.({:can_frame, msgid, 8, data, 0, -1})
  end

  defp handle_read(myid, :read_all, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_all)

    Enum.each(1..8, fn(index) ->
      val = Enum.random(1..1024) #random reading, for now
      msb = val >>> 8 |> band(0xff)
      lsb = band val, 0xff
      payload = <<0,0,0,0,0,index,msb,lsb>>
      sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
    end)

  end
  
  defp handle_read(myid, terminal, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_one)
    val = Enum.random(1..1024) #random reading, for now
    msb = val >>> 8 |> band(0xff)
    lsb = band val, 0xff
    subcommand = Canhelper.tosubcommand_read terminal
    payload = <<0,0,0,0,0,subcommand,msb,lsb>>
    sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
  end

  defp handle_readd(myid, :read_all, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_all)

    Enum.each(1..8, fn(index) ->
      val = Enum.random(1..1024) #random reading, for now
      msb = val >>> 8 |> band(0xff)
      lsb = band val, 0xff
      payload = <<0,0,0,0,index,0,msb,lsb>>
      sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
    end)

  end

  defp handle_readd(myid, terminal, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_one)
    val = Enum.random(1..1024) #random reading, for now
    msb = val >>> 8 |> band(0xff)
    lsb = band val, 0xff
    subcommand = Canhelper.tosubcommand_read terminal
    payload = <<0,0,0,0,subcommand,0,msb,lsb>>
    sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
  end

end
