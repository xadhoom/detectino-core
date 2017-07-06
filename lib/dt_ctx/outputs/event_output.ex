defmodule DtCtx.Outputs.EventOutput do
  use DtWeb.Web, :model

  schema "events_outputs" do
    belongs_to :event, Event
    belongs_to :output, Output

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:event_id, :output_id])
    |> validate_required([:event_id, :output_id])
  end
end
