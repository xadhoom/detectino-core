defmodule DtWeb.Rule do
  use DtWeb.Web, :model

  @derive {Poison.Encoder, except: [:scenario]}
  schema "rules" do
    field :name, :string
    field :expression, :string
    field :continue, :boolean, default: false
    field :priority, :integer
    field :enabled, :boolean, default: false

    belongs_to :scenario, DtWeb.Scenario

    timestamps
  end

  @required_fields ~w(name priority enabled)
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
