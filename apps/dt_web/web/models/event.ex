defmodule DtWeb.Event do
  use DtWeb.Web, :model

  schema "events" do
    field :name, :string

    timestamps

    many_to_many :outputs, DtWeb.Output, join_through: DtWeb.EventOutput
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

end
