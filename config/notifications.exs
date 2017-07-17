use Mix.Config

# configurations specific to notification stuff

config :detectino, DtCore.Output.Actions.Email.Alarm,
  sensor_start: "Sensor Alarm started",
  partition_start: "Partition Alarm started",
  sensor_end: "Sensor Alarm recovered",
  partition_end: "Partition Alarm recovered"

config :detectino, DtCore.Output.Actions.Email.DelayedAlarm,
  sensor_start: "Delayed Sensor Alarm started",
  partition_start: "Delayed Partition Alarm started",
  sensor_end: "Delayed Sensor Alarm end",
  partition_end: "Delayed Partition Alarm end"
