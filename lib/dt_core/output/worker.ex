defmodule DtCore.Output.Worker do
  @moduledoc """
  Output worker server.
  It's dispatched by the Outputs Supervisor and listens
  to all associated events, via the Registry
  """
  use GenServer

  alias DtCore.ArmEv
  alias DtCore.DetectorEntryEv
  alias DtCore.DetectorEv
  alias DtCore.Output.Actions.Bus
  alias DtCore.Output.Actions.Email
  alias DtCore.Output.Utils
  alias DtCore.OutputsRegistry
  alias DtCore.PartitionEv
  alias DtCtx.Outputs.Event, as: EventModel
  alias DtCtx.Outputs.Event.ArmEvConf
  alias DtCtx.Outputs.Event.PartitionEvConf
  alias DtCtx.Outputs.Event.SensorEvConf
  alias DtCtx.Outputs.Output, as: OutputModel
  alias DtLib.Json

  require Logger

  #
  # Client APIs
  #
  def start_link({config = %OutputModel{}}) do
    {:ok, name} = Utils.output_server_name(config)
    GenServer.start_link(__MODULE__, {config}, name: name)
  end

  def timer_expiry({t, config = %OutputModel{}}) when is_atom(t) do
    {:ok, name} = Utils.output_server_name(config)
    GenServer.call(name, {:timer_expiry, t})
  end

  #
  # GenServer callbacks
  #
  def init({config}) do
    Logger.info(fn -> "Starting Output Worker #{config.name}" end)
    {:ok, _pid} = Etimer.start_link(config.name)
    run_subscribe(config)

    state = %{
      config: config,
      t_off_running: false
    }

    {:ok, state}
  end

  def handle_call({:timer_expiry, :mono_expiry}, _from, state) do
    state =
      case state.config.type do
        "email" ->
          Logger.error("Should not have timer expiry with email outputs")
          state

        "bus" ->
          :ok = Bus.recover(state, true)
          t_off_running = Bus.off_timer(state)
          %{state | t_off_running: t_off_running}
      end

    {:reply, :ok, state}
  end

  def handle_call({:timer_expiry, :mono_off_expiry}, _from, state) do
    Logger.info("Off timer expired")
    state = %{state | t_off_running: false}
    {:reply, :ok, state}
  end

  def handle_info({:start, ev = %ArmEv{}}, state) do
    run_on_action(ev, state)
    {:noreply, state}
  end

  def handle_info({:start, ev = %DetectorEv{}}, state) do
    run_on_action(ev, state)
    {:noreply, state}
  end

  def handle_info({:start, ev = %DetectorEntryEv{}}, state) do
    run_on_action(ev, state)
    {:noreply, state}
  end

  def handle_info({:start, ev = %PartitionEv{}}, state) do
    run_on_action(ev, state)
    {:noreply, state}
  end

  def handle_info({:stop, ev = %ArmEv{}}, state) do
    run_recover_action(ev, state)
    {:noreply, state}
  end

  def handle_info({:stop, ev = %DetectorEv{}}, state) do
    run_recover_action(ev, state)
    {:noreply, state}
  end

  def handle_info({:stop, ev = %DetectorEntryEv{}}, state) do
    run_on_action(ev, state)
    {:noreply, state}
  end

  def handle_info({:stop, ev = %PartitionEv{}}, state) do
    run_recover_action(ev, state)
    {:noreply, state}
  end

  defp run_recover_action(ev, state) do
    case state.config.type do
      "email" ->
        Email.recover(ev, state.config.email_settings)

      "bus" ->
        :ok = Bus.recover(state)
    end
  end

  defp run_on_action(ev, state) do
    case state.config.type do
      "email" ->
        Email.trigger(ev, state.config.email_settings)

      "bus" ->
        :ok = Bus.trigger(state)
    end
  end

  defp run_subscribe(config) do
    case config.enabled do
      true ->
        for event <- config.events do
          subscribe(event)
        end

      _ ->
        nil
    end

    :ok
  end

  defp subscribe(_ = %EventModel{source: s, source_config: sc})
       when is_nil(s) or is_nil(sc) do
    Logger.error("Incomplete source config, not subscribing to any event")
  end

  defp subscribe(event = %EventModel{}) do
    key =
      case event.source do
        "sensor" ->
          event.source_config
          |> Json.decode_as!(SensorEvConf)
          |> get_sub_key

        "partition" ->
          event.source_config
          |> Json.decode_as!(PartitionEvConf)
          |> get_sub_key

        "arming" ->
          event.source_config
          |> Json.decode_as!(ArmEvConf)
          |> get_sub_key

        _ ->
          nil
      end

    case key do
      nil ->
        Logger.error("Empty key, not subscribing to any event")

      v when is_map(v) ->
        Registry.register(OutputsRegistry.registry(), v, [])
    end
  end

  defp get_sub_key(conf = %SensorEvConf{}) do
    %{
      source: :sensor,
      address: conf.address,
      port: conf.port,
      type: alm_str_type_to_atom(conf.type)
    }
  end

  defp get_sub_key(conf = %PartitionEvConf{}) do
    %{
      source: :partition,
      name: conf.name,
      type: alm_str_type_to_atom(conf.type)
    }
  end

  defp get_sub_key(conf = %ArmEvConf{}) do
    %{
      source: :arming,
      name: conf.name
    }
  end

  defp alm_str_type_to_atom(type) do
    case type do
      "alarm" -> :alarm
      "reading" -> :reading
      "tamper" -> :tamper
      "fault" -> :fault
      "short" -> :short
    end
  end
end
