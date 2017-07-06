defmodule DtCtx.Outputs.EmailSettings do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :from, :string
    field :to, :string
    field :body, :string
  end

  @required_fields ~w(from to)
  @optional_fields ~w(body)
  @validate_required Enum.map(@required_fields, fn(x) -> String.to_atom(x) end)
  @email_re ~r/^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/


  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@validate_required)
    |> validate_format(:to, @email_re)
    |> validate_format(:from, @email_re)
  end
end
