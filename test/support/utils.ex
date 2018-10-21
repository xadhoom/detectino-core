defmodule DtCore.Test.Utils do
  @moduledoc false
  def flush_mailbox do
    receive do
      _ -> flush_mailbox()
    after
      0 -> :ok
    end
  end
end
