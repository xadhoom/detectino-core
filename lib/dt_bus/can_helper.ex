defmodule DtBus.CanHelper do
  @moduledoc """
  Various helper fun to aid in detectino message handling
  """

  use Bitwise

  require Logger

  @commands %{1 => :ping, 2 => :pong, 3 => :event, 4 => :read, 5 => :readd}

  @fromcommands Enum.reduce(@commands, %{}, fn {k, v}, acc ->
                  Map.put(acc, v, k)
                end)

  @subcommands %{0 => :unsolicited, 1 => :reply, 2 => :read_all, 4 => :read_one}

  @fromsubcommands Enum.reduce(@subcommands, %{}, fn {k, v}, acc ->
                     Map.put(acc, v, k)
                   end)

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
    9 => :read_t9,
    10 => :read_t10,
    11 => :read_t11,
    12 => :read_t12,
    13 => :read_t13,
    14 => :read_t14,
    15 => :read_t15,
    16 => :read_t16
  }

  @fromsubcommands_read Enum.reduce(@subcommands_read, %{}, fn {k, v}, acc ->
                          Map.put(acc, v, k)
                        end)

  def command(value) when is_integer(value) do
    Map.get(@commands, value, :unk)
  end

  def tocommand(atom) when is_atom(atom) do
    Map.get(@fromcommands, atom, nil)
  end

  def subcommand(value) when is_integer(value) do
    Map.get(@subcommands, value, :unk)
  end

  def tosubcommand(atom) when is_atom(atom) do
    Map.get(@fromsubcommands, atom, nil)
  end

  def subcommand_read(value) when is_integer(value) do
    Map.get(@subcommands_read, value, :unk)
  end

  def tosubcommand_read(atom) when is_atom(atom) do
    Map.get(@fromsubcommands_read, atom, nil)
  end

  def build_msgid(sender, dest, command, subcommand)
      when (command === :read or command === :readd) and is_atom(subcommand) and
             is_integer(sender) and is_integer(dest) do
    # set EXT_BIT
    2 <<< 30
    # sender id
    |> bor(sender <<< 23)
    # dest id
    |> bor(dest <<< 16)
    # command
    |> bor(tocommand(command) <<< 8)
    # subcommand
    |> bor(tosubcommand_read(subcommand))
  end

  def build_msgid(sender, dest, command, subcommand)
      when is_atom(command) and is_atom(subcommand) and is_integer(sender) and is_integer(dest) do
    # set EXT_BIT
    2 <<< 30
    # sender id
    |> bor(sender <<< 23)
    # dest id
    |> bor(dest <<< 16)
    # command
    |> bor(tocommand(command) <<< 8)
    # subcommand
    |> bor(tosubcommand(subcommand))
  end

  def decode_msgid(msgid) when is_integer(msgid) do
    case msgid >>> 30 do
      2 ->
        # clear bit 30,31
        id = band(msgid, 0x3FFFFFFF)
        src_node_id = band(id >>> 23, 0x7F)
        dst_node_id = band(id >>> 16, 0x7F)
        command = band(id >>> 8, 0xFF) |> command()

        subcommand =
          case command do
            :read ->
              id |> band(0xFF) |> subcommand_read()

            :readd ->
              id |> band(0xFF) |> subcommand_read()

            _ ->
              id |> band(0xFF) |> subcommand()
          end

        {:ok, src_node_id, dst_node_id, command, subcommand}

      _v ->
        nil
    end
  end
end
