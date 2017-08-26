defmodule DtCtx.Outputs do
  @moduledoc """
  Entry point for outputs context

  TODO: not yet migrated to a full ctx
  """

  import Ecto.Query, only: [from: 2]

  alias DtCtx.Repo
  alias DtCtx.Outputs.EventLog

  @doc "Return the number of unacked logged events"
  @spec unacked_log_events() :: non_neg_integer()
  def unacked_log_events do
    q = from e in EventLog,
      select: count(e.id),
      where: e.acked == false
    Repo.one(q)
  end
end
