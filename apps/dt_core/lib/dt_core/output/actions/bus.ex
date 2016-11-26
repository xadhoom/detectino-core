defmodule DtCore.Output.Actions.Bus do
  @moduledoc """
  Bus action
  """
  alias DtCore.Output.Worker
  alias DtBus.ActionRegistry
  alias DtBus.OutputAction

  require Logger

  def recover(state, force \\ false) do
    bus = state.config.bus_settings
    msg = %OutputAction{
      address: bus.address,
      port: bus.port,
      command: :off
    }
    if state.config.bus_settings.type == "monostable" and !force do
      Logger.debug("Ignoring stop event on monostable outputs")
    else
      Registry.dispatch(ActionRegistry.registry, :bus_commands, fn listeners ->
        for {pid, _} <- listeners, do: send(pid, msg)
      end)
    end
    :ok
  end

  def trigger(state) do
    bus = state.config.bus_settings
    msg = %OutputAction{
      address: bus.address,
      port: bus.port,
      command: :on
    }
    if state.t_off_running do
      Logger.error "Ignoring trigger since off timer is running"
    else
      Registry.dispatch(ActionRegistry.registry, :bus_commands, fn listeners ->
        for {pid, _} <- listeners, do: send(pid, msg)
      end)
    end

    case state.config.bus_settings.type do
      "monostable" ->
        schedule_off(state)
      _ ->
        nil
    end
    :ok
  end

  def off_timer(state) do
    case state.config.bus_settings.mono_offtime do
      x when x > 0 and is_integer(x) ->
        config = state.config.bus_settings
        delay = config.mono_offtime * 1_000
        Etimer.start_timer(
          state.config.name,
          :mono_expiry, delay,
          {Worker, :timer_expiry, [:mono_off_expiry, state.config]}
          )
        true
      v ->
        Logger.warn "unhandled off time value #{inspect v}"
        false
    end
  end

  defp schedule_off(state) do
    config = state.config.bus_settings
    delay = config.mono_ontime * 1_000
    Etimer.start_timer(
      state.config.name,
      :mono_expiry, delay,
      {Worker, :timer_expiry, [:mono_expiry, state.config]}
    )
  end
end
