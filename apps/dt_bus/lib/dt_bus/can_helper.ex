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

  def build_msgid(sender, dest, command, subcommand) when 
      is_atom(command) and is_atom(subcommand) 
      and is_integer(sender) and is_integer(dest)
      do
    sender <<< 23 |> # sender id
    bor dest <<< 16 |> # dest id
    bor(tocommand(command) <<< 8) |> # command
    bor(tosubcommand(subcommand)) # subcommand
  end

  def decode_msgid(msgid) when is_integer(msgid) do
    id = band msgid, 0x3FFFFFFF
    src_node_id = id >>> 23 |> band 0x7f
    dst_node_id = id >>> 16 |> band 0x7f
    command = id >>> 8 |>  band(0xff) |> command;
    subcommand = band(id, 0xff) |> subcommand
    {:ok, src_node_id, dst_node_id, command, subcommand}
  end

end
