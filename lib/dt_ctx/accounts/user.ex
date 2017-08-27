defmodule DtCtx.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Comeonin.Bcrypt

  schema "users" do
    field :name, :string
    field :username, :string
    field :encrypted_password, :string
    field :password, :string
    field :role, :string
    field :pin, :string
    field :pin_expire, :integer

    timestamps()
  end

  def create_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(name username password role pin pin_expire))
    |> validate_required([:name, :username, :password, :role])
    |> validate_pin_expire()
    |> unique_constraint(:username)
    |> unique_constraint(:pin)
    |> maybe_update_password
  end

  def update_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(id name username password role pin pin_expire))
    |> validate_required([:id, :name, :username, :role])
    |> validate_pin_expire()
    |> unique_constraint(:username)
    |> unique_constraint(:pin)
    |> maybe_update_password
  end

  def login_changeset(model), do: model |> cast(%{}, ~w(), ~w(username password))

  def login_changeset(model, params) do
    model
    |> cast(params, ~w(username password))
    |> validate_required([:username, :password])
    |> validate_password
  end

  def valid_password?(nil, _), do: false

  def valid_password?(_, nil), do: false

  def valid_password?(password, crypted) do
    Bcrypt.checkpw(password, crypted)
  end

  defp validate_pin_expire(changeset) do
    changeset
    |> validate_number(:pin_expire, less_than_or_equal_to: 120_000)
    |> validate_number(:pin_expire, greater_than_or_equal_to: 15_000)
  end

  defp validate_password(changeset) do
    case get_field(changeset, :encrypted_password) do
      nil -> password_incorrect_error(changeset)
      crypted -> validate_password(changeset, crypted)
    end
  end

  defp validate_password(changeset, crypted) do
    password = get_change(changeset, :password)
    if valid_password?(password, crypted) do
      changeset
    else
      password_incorrect_error(changeset)
    end
  end

  defp password_incorrect_error(changeset) do
    add_error(changeset, :password, "is incorrect")
  end

  defp maybe_update_password(changeset) do
    case fetch_change(changeset, :password) do
      {:ok, password} ->
        changeset
        |> put_change(:encrypted_password,
          Bcrypt.hashpwsalt(password))
        |> put_change(:password, nil)
      :error -> changeset
    end
  end

end
