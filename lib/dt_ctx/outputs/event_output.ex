defmodule DtCtx.Outputs.EventOutput do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events_outputs" do
    belongs_to :event, DtCtx.Outputs.Event
    belongs_to :output, DtCtx.Outputs.Output

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:event_id, :output_id])
    |> validate_required([:event_id, :output_id])
  end
end
