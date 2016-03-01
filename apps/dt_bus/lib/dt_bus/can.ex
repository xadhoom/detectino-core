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
    ping: %{}

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def ping(node_id) when is_integer node_id do
    GenServer.call __MODULE__, {:ping, node_id}
  end

  def read(node_id, terminal) when is_integer node_id and is_atom terminal do
    GenServer.cast __MODULE__, {:read, node_id, terminal}
  end

  def read_all(node_id) when is_integer node_id do
    GenServer.cast __MODULE__, {:read, node_id, :read_all}
  end

  def readd(node_id, terminal) when is_integer node_id and is_atom terminal do
    GenServer.cast __MODULE__, {:readd, node_id, terminal}
  end

  def readd_all(node_id) when is_integer node_id do
    GenServer.cast __MODULE__, {:readd, node_id, :read_all}
  end

  def start_listening(filter_fun \\ fn(_) -> true end) do
    GenServer.cast(__MODULE__, {:start_listening, self, filter_fun})
  end

  def stop_listening do
    GenServer.cast(__MODULE__, {:stop_listening, self})
  end

  #
  # GenServer callbacks
  #
  def init(_) do
    Logger.info "Starting CanBus Interface"
    :can.start()
    :can_router.attach()
    cur_ifs = :can_router.interfaces
    Logger.info "Started CanBus Interface #{inspect cur_ifs}"
    {:ok, 
      %DtBus.Can{}
    }
  end

  def handle_call({:ping, node_id}, from, state) do
    Logger.debug "Pinging node #{node_id}"

    msgid = Canhelper.build_msgid(0, node_id, :ping, :unsolicited)
    payload = :crypto.rand_bytes(8)

    {:can_frame, msgid, 8, payload, 0, -1} |> :can_router.send

    ping = Dict.put_new state.ping, payload, from
    {:noreply, %{state | ping: ping}}
  end

  def handle_call(value, _from, state) do
    Logger.info "Got call message #{inspect value}"
    {:reply, nil, state}
  end

  def handle_cast({:start_listening, pid, filter_fun}, state) do
    key = Base.encode64 :erlang.term_to_binary(pid)
    listeners = Map.put state.listeners, key, %{pid: pid, filter: filter_fun}
    Process.monitor pid
    {:noreply, %DtBus.Can{state | listeners: listeners}}
  end

  def handle_cast({:stop_listening, pid}, state) do
    key = Base.encode64 :erlang.term_to_binary(pid)
    listeners = Map.delete state.listeners, key
    Process.unlink pid
    {:noreply, %DtBus.Can{state | listeners: listeners}}
  end

  def handle_cast({:read, node_id, terminal}, state) do
    Logger.debug "Reading from node #{node_id}: analog #{terminal}"

    msgid = Canhelper.build_msgid(0, node_id, :read, terminal)
    payload = <<0,0,0,0,0,0,0,0>>

    {:can_frame, msgid, 8, payload, 0, -1} |> :can_router.send

    {:noreply, state}
  end

  def handle_cast({:readd, node_id, terminal}, state) do
    Logger.debug "Reading from node #{node_id}: digital #{terminal}"

    msgid = Canhelper.build_msgid(0, node_id, :readd, terminal)
    payload = <<0,0,0,0,0,0,0,0>>

    {:can_frame, msgid, 8, payload, 0, -1} |> :can_router.send

    {:noreply, state}
  end

  def handle_cast(value, state) do
    Logger.info "Got cast message #{inspect value}"
    {:noreply, state}
  end

  def handle_info({:DOWN, _, _, pid, _}, state) do
    handle_call {:stop_listening, pid}, nil, state
    {:noreply, state}
  end

  def handle_info(what, state) do
    Logger.debug "Got info message #{inspect what}"

    case what do
      {:can_frame, _msgid, _len, _data, _intf, _ts} -> 
        {:ok, state} = handle_canframe(what, state)
      default ->
        Logger.warn "Got unknown message #{inspect default}"
    end
    {:noreply, state}
  end

  defp sendmessage(state, ev) do
    Enum.each state.listeners, fn({_, v}) ->
      if v.filter.(ev) do
        send v.pid, {:event, ev}
      end
    end
  end

  defp handle_canframe({:can_frame, msgid, len, data, _intf, _ts}, state) do
    case Canhelper.decode_msgid(msgid) do
      {:ok, src_node_id, dst_node_id, command, subcommand} ->
        Logger.info "Got command:#{command}, " <>
        "subcommand:#{subcommand} " <>
        "from id:#{src_node_id} to id:#{dst_node_id} " <>
        "datalen:#{inspect len} payload:#{inspect data}"

        if dst_node_id == 0 do
          case command do
            :pong -> 
              {:ok, state} = handle_pong(data, state)
            :event ->
              << _, _, _, _, portd, porta, msb, lsb >> = data
              value = msb <<< 8 |> bor(lsb)
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
              sendmessage(state, %Event{address: src_node_id, 
                type: :sensor, subtype: subtype, 
                port: port, value: value})
            default ->
              Logger.warn "Unhandled command #{inspect default}"
          end
        end

      _v -> nil
    end
    {:ok, state}
  end

  defp handle_pong(data, state) do
    case Dict.pop(state.ping, data) do
      {nil, _ping} -> {:ok, state}
      {from, ping} ->
        GenServer.reply from, data
        {:ok,  %{state | ping: ping}}
    end
  end

end
