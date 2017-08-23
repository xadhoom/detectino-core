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

  alias DtCore.ArmEv
  alias DtCore.DetectorEv
  alias DtCore.DetectorEntryEv
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
    |> Mailer.deliver(get_mailer_config())
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
    |> Mailer.deliver(get_mailer_config())
  end

  def custom(email, _ev = %DetectorEntryEv{}) do
    put_private(email, :delayed_event, true)
  end
  def custom(email, _ev = %DetectorEv{}) do
    put_private(email, :delayed_event, false)
  end
  def custom(email, _ev = %PartitionEv{}) do
    put_private(email, :delayed_event, false)
  end
  def custom(email, _ev) do email end

  def build_subject({:on, _ev = %ArmEv{}}) do
    get_subject(:arm_start)
  end

  def build_subject({:on, _ev = %DetectorEv{}}) do
    get_subject(:sensor_start)
  end

  def build_subject({:on, _ev = %PartitionEv{}}) do
    get_subject(:partition_start)
  end

  def build_subject({:off, _ev = %ArmEv{}}) do
    get_subject(:arm_end)
  end

  def build_subject({:off, _ev = %DetectorEv{}}) do
    get_subject(:sensor_end)
  end

  def build_subject({:off, _ev = %PartitionEv{}}) do
    get_subject(:partition_end)
  end

  def build_subject({:on, _ev = %DetectorEntryEv{}}) do
    get_delayed_subject(:sensor_start)
  end

  def build_subject({:off, _ev = %DetectorEntryEv{}}) do
    get_delayed_subject(:sensor_end)
  end

  def build_msg(ev = %ArmEv{}) do
    ev.name <> " arming by: " <> ev.initiator
  end

  def build_msg(ev = %DetectorEv{}) do
    type = Atom.to_string(ev.type)
    port = Integer.to_string(ev.port)
    type <> " from address: " <> ev.address <> ", port: " <> port
  end

  def build_msg(ev = %DetectorEntryEv{}) do
    port = Integer.to_string(ev.port)
    "Entry event from address: " <> ev.address <> ", port: " <> port
  end

  def build_msg(ev = %PartitionEv{}) do
    type = Atom.to_string(ev.type)
    type <> " from partition " <> ev.name
  end

  defp get_subject(which) when is_atom(which) do
    :detectino
    |> Application.get_env(Email.Alarm)
    |> Keyword.get(which)
  end

  defp get_delayed_subject(which) when is_atom(which) do
    :detectino
    |> Application.get_env(Email.DelayedAlarm)
    |> Keyword.get(which)
  end

  defp get_mailer_config do
    :detectino
    |> Application.get_env(Mailer)
  end

end
