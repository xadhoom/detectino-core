defmodule DtWeb.User do
  use DtWeb.Web, :model

  alias Ecto.Changeset
  alias Comeonin.Bcrypt

  schema "users" do
    field :name, :string
    field :username, :string
    field :encrypted_password, :string
    field :password, :string
    field :role, :string
    field :pin, :string

    timestamps()
  end

  def create_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(name username password role pin))
    |> validate_required([:name, :username, :password, :role])
    |> unique_constraint(:username)
    |> unique_constraint(:pin)
    |> maybe_update_password
  end

  def update_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(id name username password role pin))
    |> validate_required([:id, :name, :username, :role])
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

  defp validate_password(changeset) do
    case Changeset.get_field(changeset, :encrypted_password) do
      nil -> password_incorrect_error(changeset)
      crypted -> validate_password(changeset, crypted)
    end
  end

  defp validate_password(changeset, crypted) do
    password = Changeset.get_change(changeset, :password)
    if valid_password?(password, crypted) do
      changeset
    else
      password_incorrect_error(changeset)
    end
  end

  defp password_incorrect_error(changeset) do
    Changeset.add_error(changeset, :password, "is incorrect")
  end

  defp maybe_update_password(changeset) do
    case Changeset.fetch_change(changeset, :password) do
      {:ok, password} ->
        changeset
        |> Changeset.put_change(:encrypted_password,
          Bcrypt.hashpwsalt(password))
        |> Changeset.put_change(:password, nil)
      :error -> changeset
    end
  end

end
