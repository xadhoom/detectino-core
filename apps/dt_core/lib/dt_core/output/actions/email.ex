defmodule DtCore.Output.Actions.Email.Mailer do
  @moduledoc """
  I'm your mailer, just alias me and use Mailer
  to access to email related funs
  """
  use Swoosh.Mailer, otp_app: :dt_core
end

defmodule DtCore.Output.Actions.Email do
  @moduledoc """
  Email action
  """
  import Swoosh.Email

  alias DtCore.SensorEv
  alias DtCore.PartitionEv
  alias DtCore.Output.Actions.Email.Mailer

  def trigger(ev, config) do
    subject = build_subject(ev)
    msg = build_msg(ev)
    email = new
      |> to(config.to)
      |> from(config.from)
      |> subject(subject)
      |> text_body(msg)
      |> Mailer.deliver
  end

  def build_subject(ev = %SensorEv{}) do
    "Sensor Alarm"
  end

  def build_subject(ev = %PartitionEv{}) do
    "Partition Alarm"
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
