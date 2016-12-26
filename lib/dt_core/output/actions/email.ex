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
  alias DtCore.Output.Actions.Email.Mailer

  def recover(ev, config) do
    subject = build_subject({:off, ev})
    msg = build_msg(ev)
    email = new
      |> to(config.to)
      |> from(config.from)
      |> subject(subject)
      |> text_body(msg)
      |> Mailer.deliver
  end

  def trigger(ev, config) do
    subject = build_subject({:on, ev})
    msg = build_msg(ev)
    email = new
      |> to(config.to)
      |> from(config.from)
      |> subject(subject)
      |> text_body(msg)
      |> Mailer.deliver
  end

  def build_subject({:on, ev = %SensorEv{}}) do
    "Sensor Alarm started"
  end

  def build_subject({:on, ev = %PartitionEv{}}) do
    "Partition Alarm started"
  end

  def build_subject({:off, ev = %SensorEv{}}) do
    "Sensor Alarm recovered"
  end

  def build_subject({:off, ev = %PartitionEv{}}) do
    "Partition Alarm recovered"
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
end
