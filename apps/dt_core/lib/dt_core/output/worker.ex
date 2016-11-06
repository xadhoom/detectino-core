defmodule DtCore.Output.Worker do
  @moduledoc """
  Output worker server.
  It's dispatched by the Outputs Supervisor and listens
  to all associated events, via the Registry
  """
  use GenServer

  require Logger
  alias DtCore.Output.Utils
  alias DtWeb.Output, as: OutputModel
  alias DtWeb.Event, as: EventModel
  alias DtWeb.Event.SensorEvConf
  alias DtWeb.Event.PartitionEvConf
  alias DtCore.EvRegistry
  alias DtCore.SensorEv
  alias DtCore.PartitionEv
  alias DtCore.Output.Actions.Bus
  alias DtCore.Output.Actions.Email

  #
  # Client APIs
  #
  def start_link({config = %OutputModel{}}) do
    {:ok, name} = Utils.output_server_name(config)
    GenServer.start_link(__MODULE__, {config}, name: name)
  end

  #
  # GenServer callbacks
  #
  def init({config}) do
    Logger.info "Starting Output Worker #{config.name}"
    run_subscribe(config)
    state = %{config: config}
    {:ok, state}
  end

  def handle_info(ev = %SensorEv{}, state) do
    run_action(ev, state)
    {:noreply, state}
  end

  def handle_info(ev = %PartitionEv{}, state) do
    run_action(ev, state)
    {:noreply, state}
  end

  defp run_action(ev, state) do
    case state.config.type do
      "email" ->
        Email.trigger(ev, state.config.email_settings)
      "bus" ->
        Bus.trigger(ev, state.config.email_settings)
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
    key = case event.source do
      "sensor" ->
        event.source_config
        |> Poison.decode!(as: %SensorEvConf{})
        |> get_sub_key
      "partition" ->
        event.source_config
        |> Poison.decode!(as: %PartitionEvConf{})
        |> get_sub_key
      _ -> nil
    end

    case key do
      nil ->
        Logger.error("Empty key, not subscribing to any event")
      v when is_map v ->
        Registry.register(EvRegistry.registry, v, [])
    end
  end

  defp get_sub_key(conf = %SensorEvConf{}) do
    %{
      source: :sensor, address: conf.address, port: conf.port,
      type: alm_str_type_to_atom(conf.type)
    }
  end

  defp get_sub_key(conf = %PartitionEvConf{}) do
    %{
      source: :partition, name: conf.name,
      type: alm_str_type_to_atom(conf.type)
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
