defmodule DtWeb.EmailSettings do
  use DtWeb.Web, :model

  embedded_schema do
    field :sender
    field :address
    field :body
  end

  @required_fields ~w(sender, address, body)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
