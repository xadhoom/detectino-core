defmodule DtBus.Can do
  @moduledoc """
  CAN BUS is used with extended frame format. This allows 29 bit identifiers.
  We use the 7 MSBs as node id.

  Please note that we don't use message ids to handle also priority,
  where in can bus lower message id has higher priority, since we don't need it.
  I prefered (and need) to build the id to be able to address each node
  in order to get where it is and what it has attached to it.

  Special nodes id:
  0x0 : the master node (raspberry in detectino project).
  0x7f: the broadcast address

  The other bits are used to identify destination and commands.

  so here's the bit map:
  23-29 : node id (source, read from dips)
  16-22 : destination node id
   8-15 : command
   0- 7 : subcommand
  """
  use GenServer
  use Bitwise

  alias DtBus.Event, as: Event
  alias DtBus.CanHelper, as: Canhelper

  require Logger

  defstruct listeners: %{},
            ping: %{},
            debug: false

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def ping(node_id) when is_integer(node_id) do
    GenServer.call(__MODULE__, {:ping, node_id})
  end

  def read(node_id, terminal) when is_integer(node_id) and is_atom(terminal) do
    GenServer.cast(__MODULE__, {:read, node_id, terminal})
  end

  def read_all(node_id) when is_integer(node_id) do
    GenServer.cast(__MODULE__, {:read, node_id, :read_all})
  end

  def readd(node_id, terminal) when is_integer(node_id) and is_atom(terminal) do
    GenServer.cast(__MODULE__, {:readd, node_id, terminal})
  end

  def readd_all(node_id) when is_integer(node_id) do
    GenServer.cast(__MODULE__, {:readd, node_id, :read_all})
  end

  def start_listening(filter_fun \\ fn _ -> true end) do
    GenServer.call(__MODULE__, {:start_listening, self(), filter_fun})
  end

  def stop_listening do
    GenServer.call(__MODULE__, {:stop_listening, self()})
  end

  #
  # GenServer callbacks
  #
  def init(_) do
    Logger.info("Starting CanBus Interface")
    :can.start()
    :can_router.attach()
    c_if = Application.get_env(:detectino, :can_interface)
    :can_sock.start(0, [{:device, c_if}])
    cur_ifs = :can_router.interfaces()
    Logger.info(fn -> "Started CanBus Interface #{inspect(cur_ifs)}" end)
    {:ok, %DtBus.Can{}}
  end

  def handle_call({:ping, node_id}, from, state) do
    Logger.debug(fn -> "Pinging node #{node_id}" end)

    msgid = Canhelper.build_msgid(0, node_id, :ping, :unsolicited)
    payload = :crypto.strong_rand_bytes(8)

    {:can_frame, msgid, 8, payload, 0, -1} |> :can_router.send()

    ping = Map.put_new(state.ping, payload, from)
    {:noreply, %{state | ping: ping}}
  end

  def handle_call({:start_listening, pid, filter_fun}, _from, state) do
    key = Base.encode64(:erlang.term_to_binary(pid))
    listeners = Map.put(state.listeners, key, %{pid: pid, filter: filter_fun})
    Process.monitor(pid)
    {:reply, {:ok, pid}, %DtBus.Can{state | listeners: listeners}}
  end

  def handle_call({:stop_listening, pid}, _from, state) do
    key = Base.encode64(:erlang.term_to_binary(pid))
    listeners = Map.delete(state.listeners, key)
    Process.unlink(pid)
    {:reply, {:ok, pid}, %DtBus.Can{state | listeners: listeners}}
  end

  def handle_call(value, _from, state) do
    Logger.debug(fn -> "Got call message #{inspect(value)}" end)
    {:reply, nil, state}
  end

  def handle_cast({:read, node_id, terminal}, state) do
    Logger.debug(fn -> "Reading from node #{node_id}: analog #{terminal}" end)

    msgid = Canhelper.build_msgid(0, node_id, :read, terminal)
    payload = <<0, 0, 0, 0, 0, 0, 0, 0>>

    {:can_frame, msgid, 8, payload, 0, -1} |> :can_router.send()

    {:noreply, state}
  end

  def handle_cast({:readd, node_id, terminal}, state) do
    Logger.debug(fn -> "Reading from node #{node_id}: digital #{terminal}" end)

    msgid = Canhelper.build_msgid(0, node_id, :readd, terminal)
    payload = <<0, 0, 0, 0, 0, 0, 0, 0>>

    {:can_frame, msgid, 8, payload, 0, -1} |> :can_router.send()

    {:noreply, state}
  end

  def handle_cast({:send, _}, state) do
    # ignore :send messages sent by the can router
    {:noreply, state}
  end

  def handle_cast(value, state) do
    Logger.warn(fn -> "Got unhandled cast message #{inspect(value)}" end)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, _, pid, _}, state) do
    handle_call({:stop_listening, pid}, nil, state)
    {:noreply, state}
  end

  def handle_info({:more_debug, v}, state) when is_boolean(v) do
    Logger.info(fn -> "Setting can more debug at #{inspect(v)}" end)
    newstate = %{state | debug: v}
    {:noreply, newstate}
  end

  def handle_info(what, state) do
    debug_log(fn -> "Got info message #{inspect(what)}" end, state)

    {:ok, state} =
      case what do
        {:can_frame, _msgid, _len, _data, _intf, _ts} ->
          {:ok, _state} = handle_canframe(what, state)

        default ->
          Logger.warn(fn -> "Got unknown message #{inspect(default)}" end)
      end

    {:noreply, state}
  end

  defp sendmessage(state, ev) do
    Enum.each(state.listeners, fn {_, v} ->
      if v.filter.(ev) do
        send(v.pid, {:event, ev})
      end
    end)
  end

  defp handle_canframe({:can_frame, msgid, len, data, _intf, _ts}, state) do
    {:ok, state} =
      case Canhelper.decode_msgid(msgid) do
        {:ok, src_node_id, dst_node_id, command, subcommand} ->
          debug_log(
            fn ->
              "Got command:#{command}, " <>
                "subcommand:#{subcommand} " <>
                "from id:#{src_node_id} to id:#{dst_node_id} " <>
                "datalen:#{inspect(len)} payload:#{inspect(data)}"
            end,
            state
          )

          if dst_node_id == 0 do
            case command do
              :pong ->
                {:ok, _state} = handle_pong(data, state)

              :event ->
                <<_, _, _, _, portd, porta, msb, lsb>> = data
                value = bor(msb <<< 8, lsb)

                port =
                  case porta do
                    0 -> portd
                    _ -> porta
                  end

                subtype =
                  case porta do
                    0 -> :digital_read
                    _ -> :analog_read
                  end

                sendmessage(state, %Event{
                  address: src_node_id,
                  type: :sensor,
                  subtype: subtype,
                  port: port,
                  value: value
                })

                {:ok, state}

              default ->
                Logger.warn(fn -> "Unhandled command #{inspect(default)}" end)
                {:ok, state}
            end
          end

        _v ->
          {:ok, state}
      end

    {:ok, state}
  end

  defp handle_pong(data, state) do
    case Map.pop(state.ping, data) do
      {nil, _pingrq} ->
        {:ok, state}

      {from, pingrq} ->
        GenServer.reply(from, data)
        {:ok, %{state | ping: pingrq}}
    end
  end

  defp debug_log(what, state) do
    case state.debug do
      true -> Logger.debug(what)
      _ -> nil
    end
  end
end
