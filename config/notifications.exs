use Mix.Config

# configurations specific to notification stuff

config :detectino, DtCore.Output.Actions.Email,
  alarm_subjects: %{
    sensor_start: "Sensor Alarm started",
    partition_start: "Partition Alarm started",
    sensor_end: "Sensor Alarm recovered",
    partition_end: "Partition Alarm recovered",
  },
  delayed_alarm_subjects: %{
    sensor_start: "Delayed Sensor Alarm started",
    partition_start: "Delayed Partition Alarm started",
    sensor_end: "Delayed Sensor Alarm end",
    partition_end: "Delayed Partition Alarm end",
  }
