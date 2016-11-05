defmodule DtCore.Output.Actions.Email do
  @moduledoc """
  Email action
  """
  use Swoosh.Mailer, otp_app: :dt_core
end
