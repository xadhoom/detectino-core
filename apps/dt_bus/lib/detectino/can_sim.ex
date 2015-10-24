defmodule Dt.Bus.Cansim do
  use GenServer
  use Bitwise

  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :detectino_sim)
  end

  def init(_) do
    :timer.send_interval(10000, :status)
    {:ok, nil}
  end

  def handle_call(value, state) do
    Logger.debug "Got call message #{inspect value}"
    {:reply, state}
  end

  def handle_cast(value, state) do
    Logger.debug "Got cast message #{inspect value}"
    {:noreply, state}
  end

  def handle_info(:status, state) do
    Logger.debug "Sending can frame"
    id = 125 <<< 23 |> # sender id
      bor 0 <<< 16 |> # dest id
      bor 3 <<< 8 |> # command
      bor 0 # subcommand

    # send random analog reads...
    Enum.each(1..8, fn(index) ->
      val = Enum.random(1..1024) #random reading, for now
      msb = val >>> 8 |> band 0xff
      lsb = band val, 0xff
      payload = <<0,0,0,0,0,index,msb,lsb>>
      {:can_frame, id, 8, payload, 0, -1} |> :can_router.send
    end)

    # send random digital reads...
    Enum.each(1..3, fn(index) ->
      val = Enum.random(0..1) #random reading, for now
      payload = <<0,0,0,0,index,0,0,val>>
      {:can_frame, id, 8, payload, 0, -1} |> :can_router.send
    end)
    {:noreply, state}
  end

  def handle_info(value, state) do
    Logger.debug "Got info message #{inspect value}"
    {:noreply, state}
  end

end
