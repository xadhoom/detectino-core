defmodule DtCore.Output.Actions.Email.Mailer do
  @moduledoc """
  I'm your mailer, just alias me and use Mailer
  to access to email related funs
  """
  use Swoosh.Mailer, otp_app: :detectino
end

defmodule DtCore.Output.Actions.Email do
  @moduledoc """
  Email action
  """
  import Swoosh.Email

  alias DtCore.SensorEv
  alias DtCore.PartitionEv
  alias DtCore.Output.Actions.Email
  alias DtCore.Output.Actions.Email.Mailer

  def recover(ev, config) do
    subject = build_subject({:off, ev})
    msg = build_msg(ev)
    new()
    |> custom(ev)
    |> to(config.to)
    |> from(config.from)
    |> subject(subject)
    |> text_body(msg)
    |> Mailer.deliver
  end

  def trigger(ev, config) do
    subject = build_subject({:on, ev})
    msg = build_msg(ev)
    new()
    |> custom(ev)
    |> to(config.to)
    |> from(config.from)
    |> subject(subject)
    |> text_body(msg)
    |> Mailer.deliver
  end

  def custom(email, _ev = %SensorEv{delayed: true}) do
    put_private(email, :delayed_event, true)
  end
  def custom(email, _ev = %SensorEv{delayed: false}) do
    put_private(email, :delayed_event, false)
  end
  def custom(email, _ev = %PartitionEv{delayed: true}) do
    put_private(email, :delayed_event, true)
  end
  def custom(email, _ev = %PartitionEv{delayed: false}) do
    put_private(email, :delayed_event, false)
  end
  def custom(email, _ev) do email end

  def build_subject({:on, _ev = %SensorEv{delayed: false}}) do
    get_subject(:sensor_start)
  end

  def build_subject({:on, _ev = %PartitionEv{delayed: false}}) do
    get_subject(:partition_start)
  end

  def build_subject({:off, _ev = %SensorEv{delayed: false}}) do
    get_subject(:sensor_end)
  end

  def build_subject({:off, _ev = %PartitionEv{delayed: false}}) do
    get_subject(:partition_end)
  end

  def build_subject({:on, _ev = %SensorEv{delayed: true}}) do
    get_delayed_subject(:sensor_start)
  end

  def build_subject({:on, _ev = %PartitionEv{delayed: true}}) do
    get_delayed_subject(:partition_start)
  end

  def build_subject({:off, _ev = %SensorEv{delayed: true}}) do
    get_delayed_subject(:sensor_end)
  end

  def build_subject({:off, _ev = %PartitionEv{delayed: true}}) do
    get_delayed_subject(:partition_end)
  end

  def build_msg(ev = %SensorEv{}) do
    type = Atom.to_string(ev.type)
    port = Integer.to_string(ev.port)
    type <> " from address: " <> ev.address <> ", port: " <> port
  end

  def build_msg(ev = %PartitionEv{}) do
    type = Atom.to_string(ev.type)
    type <> " from partition " <> ev.name
  end

  defp get_subject(which) when is_atom(which) do
    :detectino
    |> Application.get_env(Email)
    |> Keyword.get(:alarm_subjects)
    |> Map.get(which)
  end

  defp get_delayed_subject(which) when is_atom(which) do
    :detectino
    |> Application.get_env(Email)
    |> Keyword.get(:delayed_alarm_subjects)
    |> Map.get(which)
  end

end
