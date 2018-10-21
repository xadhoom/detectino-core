defmodule DtBus.CanSim do
  @moduledoc """
  Provide a CanBus simulator to aid in development and testing.
  """
  use GenServer
  use Bitwise

  alias DtBus.CanHelper, as: Canhelper

  require Logger

  @send_interval 500

  #
  # Client APIs
  #
  def start_link(myid, sender_fn \\ &:can_router.send(&1))
      when is_integer(myid) and myid > 0 and myid < 127 do
    GenServer.start_link(__MODULE__, {myid, sender_fn}, name: __MODULE__)
  end

  def flood do
    GenServer.call(__MODULE__, {:flood})
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

  def stop do
    GenServer.call(__MODULE__, {:stop})
  end

  #
  # GenServer Callbacks
  #
  def init({myid, sender_fn}) do
    :can_router.attach()
    {:ok, %{myid: myid, sender_fn: sender_fn, flood: false, running: nil}}
  end

  def handle_call({:flood}, _f, state) do
    case state.flood do
      true -> {:reply, :disabled, %{state | flood: false}}
      false -> {:reply, :enabled, %{state | flood: true}}
    end
  end

  def handle_call({:stop}, _from, state) do
    case state.running do
      tref when is_reference(tref) ->
        Process.cancel_timer(tref)

      _ ->
        nil
    end

    state = %{state | running: nil}
    {:reply, :ok, state}
  end

  def handle_call(cmd = {:gen_analog_ev, _port, _value}, _f, state) do
    case state.running do
      tref when is_reference(tref) ->
        Process.cancel_timer(tref)

      _ ->
        nil
    end

    tref = Process.send_after(self(), cmd, @send_interval)
    state = %{state | running: tref}
    {:reply, :ok, state}
  end

  def handle_call(value, _from, state) do
    Logger.debug(fn -> "Got call message #{inspect(value)}" end)
    {:reply, nil, state}
  end

  def handle_cast(value, state) do
    Logger.debug(fn -> "Got cast message #{inspect(value)}" end)
    {:noreply, state}
  end

  def handle_info({:can_frame, msgid, len, data, _intf, _ts}, state) do
    case Canhelper.decode_msgid(msgid) do
      {:ok, src_node_id, dst_node_id, command, subcommand} ->
        if dst_node_id == state.myid do
          Logger.info(
            "Got command:#{command}, " <>
              "subcommand:#{subcommand} " <>
              "from id:#{src_node_id} to id:#{dst_node_id} " <>
              "datalen:#{inspect(len)} payload:#{inspect(data)}"
          )

          command |> handle_can_command(subcommand, src_node_id, data, state)
        end

      _v ->
        nil
    end

    {:noreply, state}
  end

  def handle_info(cmd = {:gen_analog_ev, port, value}, state) do
    send_analog_can_message(value, port, state)

    tref =
      with v when is_reference(v) <- state.running,
           true <- state.flood do
        Process.send_after(self(), cmd, @send_interval)
      else
        _ -> nil
      end

    {:noreply, %{state | running: tref}}
  end

  def handle_info(value, state) do
    Logger.debug(fn -> "Got info message #{inspect(value)}" end)
    {:noreply, state}
  end

  defp handle_ping(myid, src_node_id, data, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :pong, :reply)

    {:can_frame, msgid, 8, data, 0, -1}
    |> sender_fn.()
  end

  defp handle_read(myid, :read_all, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_all)

    Enum.each(1..8, fn index ->
      # random reading, for now
      val = Enum.random(1..1024)
      msb = band(val >>> 8, 0xFF)
      lsb = band(val, 0xFF)
      payload = <<0, 0, 0, 0, 0, index, msb, lsb>>

      {:can_frame, msgid, 8, payload, 0, -1}
      |> sender_fn.()
    end)
  end

  defp handle_read(myid, terminal, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_one)
    # random reading, for now
    val = Enum.random(1..1024)
    msb = band(val >>> 8, 0xFF)
    lsb = band(val, 0xFF)
    subcommand = Canhelper.tosubcommand_read(terminal)
    payload = <<0, 0, 0, 0, 0, subcommand, msb, lsb>>

    {:can_frame, msgid, 8, payload, 0, -1}
    |> sender_fn.()
  end

  defp handle_readd(myid, :read_all, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_all)

    Enum.each(1..8, fn index ->
      # random reading, for now
      val = Enum.random(1..1024)
      msb = band(val >>> 8, 0xFF)
      lsb = band(val, 0xFF)
      payload = <<0, 0, 0, 0, index, 0, msb, lsb>>

      {:can_frame, msgid, 8, payload, 0, -1}
      |> sender_fn.()
    end)
  end

  defp handle_readd(myid, terminal, src_node_id, sender_fn) do
    msgid = Canhelper.build_msgid(myid, src_node_id, :event, :read_one)
    # random reading, for now
    val = Enum.random(1..1024)
    msb = band(val >>> 8, 0xFF)
    lsb = band(val, 0xFF)
    subcommand = Canhelper.tosubcommand_read(terminal)
    payload = <<0, 0, 0, 0, subcommand, 0, msb, lsb>>

    {:can_frame, msgid, 8, payload, 0, -1}
    |> sender_fn.()
  end

  defp send_analog_can_message(value, port, state) do
    msgid = Canhelper.build_msgid(state.myid, 0, :event, :unsolicited)
    msb = band(value >>> 8, 0xFF)
    lsb = band(value, 0xFF)
    payload = <<0, 0, 0, 0, 0, port, msb, lsb>>

    {:can_frame, msgid, 8, payload, 0, -1}
    |> state.sender_fn.()
  end

  defp handle_can_command(command, subcommand, src_node_id, data, state) do
    case command do
      :ping ->
        handle_ping(state.myid, src_node_id, data, state.sender_fn)

      :read ->
        handle_read(state.myid, subcommand, src_node_id, state.sender_fn)

      :readd ->
        handle_readd(state.myid, subcommand, src_node_id, state.sender_fn)

      unh ->
        Logger.warn("Unhandled can command #{inspect(unh)}")
    end
  end
end
