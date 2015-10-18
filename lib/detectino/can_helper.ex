defmodule Detectino.Canhelper do
  require Logger

  @commands %{1 => :ping, 
              2 => :pong,
              3 => :event,
              4 => :read,
              5 => :readd}

  @subcommands %{0 => :unsolicited,
                 1 => :reply,
                 2 => :read_all,
                 4 => :read_one
               }
  
  def command(value) when is_integer(value) do
    Map.get(@commands, value, :unk)
  end

  def subcommand(value) when is_integer(value) do
    Map.get(@subcommands, value, :unk)
  end

end
