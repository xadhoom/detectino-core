defmodule DtBus.Can do
  use GenServer
  use Bitwise

  alias DtBus.Canhelper, as: Canhelper

  require Logger

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :detectino_can)
  end

  def ping(name, node_id) when is_integer node_id do
    GenServer.call name, {:ping, node_id}
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
    {:ok, nil}
  end

  def handle_call({:ping, node_id}, _from, state) do
    Logger.debug "Got ping request"

    msgid = Canhelper.build_msgid(0, node_id, :ping, :unsolicited)
    payload = <<"DEADBEEF">>
    {:can_frame, msgid, 8, payload, 0, -1} |> :can_router.send
    {:reply, :ok, state}
  end

  def handle_call(value, _from, state) do
    Logger.info "Got call message #{inspect value}"
    {:reply, nil, state}
  end

  def handle_cast(value, state) do
    Logger.info "Got cast message #{inspect value}"
    {:noreply, state}
  end

  def handle_info(what, state) do
    Logger.debug "Got info message #{inspect what}"

    case what do
      {:can_frame, _msgid, _len, _data, _intf, _ts} -> handle_canframe(what)
      default -> Logger.warn "Got unknown message #{inspect default}"
    end
    {:noreply, state}
  end

  @doc """
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
  defp handle_canframe({:can_frame, msgid, len, data, _intf, _ts}) do
    {:ok, src_node_id, dst_node_id, command, subcommand} = Canhelper.decode_msgid(msgid)
    Logger.info "Got command:#{command}, " <>
    "subcommand:#{subcommand} " <>
    "from id:#{src_node_id} to id:#{dst_node_id} " <>
    "datalen:#{inspect len} payload:#{inspect data}"
  end

end
