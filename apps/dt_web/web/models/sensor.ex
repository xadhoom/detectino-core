defmodule DtWeb.Sensor do
  use DtWeb.Web, :model

  schema "sensors" do
    field :address, :string
    field :name, :string
    field :type_id, :integer
    field :configured, :boolean, default: false

    timestamps
  end

  @required_fields ~w(address name type_id configured)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
