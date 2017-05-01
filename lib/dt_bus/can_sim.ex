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

  def short(port, value \\ 50) do
    GenServer.call(__MODULE__, {:gen_analog_ev, port, value})
  end

  def idle(port, value \\ 200) do
    GenServer.call(__MODULE__, {:gen_analog_ev, port, value})
  end

  def alarm(port, value \\ 300) do
    GenServer.call(__MODULE__, {:gen_analog_ev, port, value})
  end

  def fault(port, value \\ 400) do
    # only on grade 3 sensors is available
    GenServer.call(__MODULE__, {:gen_analog_ev, port, value})
  end

  def open(port, value \\ 600) do
    GenServer.call(__MODULE__, {:gen_analog_ev, port, value})
  end

  #
  # GenServer Callbacks
  #
  def init({myid, sender_fn}) do
    :can_router.attach()
    {:ok, %{myid: myid, sender_fn: sender_fn}}
  end

  def handle_call({:autorun}, _from, state) do
    :timer.send_interval(10_000, :status)
    {:reply, :ok, state}
  end

  def handle_call({:gen_analog_ev, port, value}, _from, state) do
    send_analog_can_message(value, port, state)
    {:reply, :ok, state}
  end

  def handle_call(value, _from, state) do
    Logger.debug fn -> "Got call message #{inspect value}" end
    {:reply, nil, state}
  end

  def handle_cast(value, state) do
    Logger.debug fn -> "Got cast message #{inspect value}" end
    {:noreply, state}
  end

  def handle_info({:can_frame, msgid, len, data, _intf, _ts}, state) do
    case Canhelper.decode_msgid(msgid) do
      {:ok, src_node_id, dst_node_id, command, subcommand} ->
        if dst_node_id == state.myid do
          Logger.info fn -> "Got command:#{command}, " <>
            "subcommand:#{subcommand} " <>
            "from id:#{src_node_id} to id:#{dst_node_id} " <>
            "datalen:#{inspect len} payload:#{inspect data}" end
          case command do
            :ping ->
              handle_ping(state.myid, src_node_id, data, state.sender_fn)
            :read ->
              handle_read(state.myid, subcommand, src_node_id, state.sender_fn)
            :readd ->
              handle_readd(state.myid, subcommand, src_node_id, state.sender_fn)
            unh ->
              Logger.warn fn -> "Unhandled can command #{inspect unh}" end
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
      send_analog_can_message(val, index, state)
    end)

    # send random digital reads...
    Enum.each(1..3, fn(index) ->
      val = Enum.random(0..1) #random reading, for now
      payload = <<0, 0, 0, 0, index, 0, 0, val>>
      state.sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
    end)
    {:noreply, state}
  end

  def handle_info(value, state) do
    Logger.debug fn -> "Got info message #{inspect value}" end
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
      msb = band(val >>> 8, 0xff)
      lsb = band val, 0xff
      payload = <<0, 0, 0, 0, 0, index, msb, lsb>>
      sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
    end)

  end

  defp handle_read(myid, terminal, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_one)
    val = Enum.random(1..1024) #random reading, for now
    msb = band(val >>> 8, 0xff)
    lsb = band(val, 0xff)
    subcommand = Canhelper.tosubcommand_read terminal
    payload = <<0, 0, 0, 0, 0, subcommand, msb, lsb>>
    sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
  end

  defp handle_readd(myid, :read_all, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_all)

    Enum.each(1..8, fn(index) ->
      val = Enum.random(1..1024) #random reading, for now
      msb = band(val >>> 8, 0xff)
      lsb = band(val, 0xff)
      payload = <<0, 0, 0, 0, index, 0, msb, lsb>>
      sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
    end)

  end

  defp handle_readd(myid, terminal, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_one)
    val = Enum.random(1..1024) #random reading, for now
    msb = band(val >>> 8, 0xff)
    lsb = band(val, 0xff)
    subcommand = Canhelper.tosubcommand_read terminal
    payload = <<0, 0, 0, 0, subcommand, 0, msb, lsb>>
    sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
  end

  defp send_analog_can_message(value, port, state) do
    msgid = Canhelper.build_msgid(state.myid, 0, :event, :unsolicited)
    msb = band(value >>> 8, 0xff)
    lsb = band value, 0xff
    payload = <<0, 0, 0, 0, 0, port, msb, lsb>>
    state.sender_fn.({:can_frame, msgid, 8, payload, 0, -1})
  end

end
