defmodule DtWeb.OutputTest do
  use DtWeb.ModelCase

  alias DtCtx.Outputs.Output

  test "changeset with invalid type" do
    attrs = %{name: "some content", type: "type", enabled: true}
    changeset = Output.create_changeset(%Output{}, attrs)
    refute changeset.valid?
  end

  test "changeset with missing enabled field" do
    attrs = %{name: "some content", type: "email"}
    changeset = Output.create_changeset(%Output{}, attrs)
    refute changeset.valid?
  end

  test "changeset with wrong enabled field" do
    attrs = %{name: "some content", type: "email", enabled: "wrong"}
    changeset = Output.create_changeset(%Output{}, attrs)
    refute changeset.valid?
  end

  test "email output type" do
    settings = %{from: "bob@example.com", to: "alice@example.com"}
    attrs = %{name: "some content", type: "email", enabled: true,
      email_settings: settings
    }
    changeset = Output.create_changeset(%Output{}, attrs)
    assert changeset.valid?

    settings = %{from: "bob@example.com", to: "alice@example.com",
      body: "content"
    }
    attrs = %{attrs | email_settings: settings}
    changeset = Output.create_changeset(%Output{}, attrs)
    assert changeset.valid?

    settings = %{from: "bob@example.com", to: "alice@"}
    attrs = %{attrs | email_settings: settings}
    changeset = Output.create_changeset(%Output{}, attrs)
    refute changeset.valid?

    settings = %{from: "bob", to: "alice@example.com"}
    attrs = %{attrs | email_settings: settings}
    changeset = Output.create_changeset(%Output{}, attrs)
    refute changeset.valid?
  end

  test "bus output type" do
    settings = %{address: "10", port: 1, type: "monostable"}
    attrs = %{name: "some content", type: "bus", enabled: true,
      bus_settings: settings
    }
    changeset = Output.create_changeset(%Output{}, attrs)
    refute changeset.valid?

    settings = %{address: "10", port: 1, type: "monostable",
      mono_ontime: 5}
    attrs = %{name: "some content", type: "bus", enabled: true,
      bus_settings: settings
    }
    changeset = Output.create_changeset(%Output{}, attrs)
    assert changeset.valid?

    settings = %{address: "10", port: 1, type: "bistable"}
    attrs = %{attrs | bus_settings: settings}
    changeset = Output.create_changeset(%Output{}, attrs)
    assert changeset.valid?

    settings = %{address: "10", port: 1, type: "somestable"}
    attrs = %{attrs | bus_settings: settings}
    changeset = Output.create_changeset(%Output{}, attrs)
    refute changeset.valid?
  end

end
