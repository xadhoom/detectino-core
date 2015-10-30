defmodule DtBus.CanHelper do
  use Bitwise

  require Logger

  @commands %{1 => :ping, 
              2 => :pong,
              3 => :event,
              4 => :read,
              5 => :readd}

  @fromcommands Enum.map(@commands, fn({k, v}) -> {v, k} end)

  @subcommands %{0 => :unsolicited,
                 1 => :reply,
                 2 => :read_all,
                 4 => :read_one
               }

  @fromsubcommands Enum.map(@subcommands, fn({k, v}) -> {v, k} end)

  @subcommands_read %{
                    0 => :read_all,
                    1 => :read_t1,
                    2 => :read_t2,
                    3 => :read_t3,
                    4 => :read_t4,
                    5 => :read_t5,
                    6 => :read_t6,
                    7 => :read_t7,
                    8 => :read_t8,
                    8 => :read_t9,
                    10 => :read_t10,
                    11 => :read_t11,
                    12 => :read_t12,
                    13 => :read_t13,
                    14 => :read_t14,
                    15 => :read_t15,
                    16 => :read_t16
                    }
  
  @fromsubcommands_read Enum.map(@subcommands_read, fn({k, v}) -> {v, k} end)

  def command(value) when is_integer(value) do
    Map.get(@commands, value, :unk)
  end

  def tocommand(atom) when is_atom(atom) do
    Dict.get(@fromcommands, atom, nil)
  end

  def subcommand(value) when is_integer(value) do
    Map.get(@subcommands, value, :unk)
  end

  def tosubcommand(atom) when is_atom(atom) do
    Dict.get(@fromsubcommands, atom, nil)
  end

  def subcommand_read(value) when is_integer(value) do
    Map.get(@subcommands_read, value, :unk)
  end

  def tosubcommand_read(atom) when is_atom(atom) do
    Dict.get(@fromsubcommands_read, atom, nil)
  end

  def build_msgid(sender, dest, :read, subcommand) when 
      is_atom(subcommand) and is_integer(sender) and is_integer(dest)
      do
    Logger.warn "#{inspect subcommand}"
    2 <<< 30 |> # set EXT_BIT
    bor sender <<< 23 |> # sender id
    bor dest <<< 16 |> # dest id
    bor(tocommand(:read) <<< 8) |> # command
    bor(tosubcommand_read(subcommand)) # subcommand
  end

  def build_msgid(sender, dest, command, subcommand) when 
      is_atom(command) and is_atom(subcommand) 
      and is_integer(sender) and is_integer(dest)
      do
    2 <<< 30 |> # set EXT_BIT
    bor sender <<< 23 |> # sender id
    bor dest <<< 16 |> # dest id
    bor(tocommand(command) <<< 8) |> # command
    bor(tosubcommand(subcommand)) # subcommand
  end

  def decode_msgid(msgid) when is_integer(msgid) do
    case msgid >>> 30 do
      2 ->
        id = band msgid, 0x3FFFFFFF # clear bit 30,31
        src_node_id = id >>> 23 |> band 0x7f
        dst_node_id = id >>> 16 |> band 0x7f
        command = id >>> 8 |>  band(0xff) |> command
        case command do
          :read ->
            subcommand = band(id, 0xff) |> subcommand_read
          _ ->
            subcommand = band(id, 0xff) |> subcommand
        end

        {:ok, src_node_id, dst_node_id, command, subcommand}
      v ->
        Logger.warn "Not handled #{inspect msgid}"
        nil
    end
  end

end
