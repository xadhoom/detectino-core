defmodule DtCore.RulesTest do
  use ExUnit.Case, async: true

  alias DtCore.Rule

  test "check rule against numerical value" do
    event = %DtCore.Event{address: "1234", port: 10, value: 1, type: :an_atom, subtype: :another_atom}

    grammar = Rule.load

    assert true == Rule.apply grammar, event, 'if event.value == 1 then true'
    assert true == Rule.apply grammar, event, 'if event.value > 0 then true'
    assert false == Rule.apply grammar, event, 'if event.value != 2 then false'
  end

  test "rule against atom fields in event" do
    grammar = Rule.load

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert true == Rule.apply grammar, event, 'if event.type == an_atom then true'

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert true == Rule.apply grammar, event, 'if event.subtype == another_atom then true'
  end

  test "check rule against string value" do
    grammar = Rule.load

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert true == Rule.apply grammar, event, 'if event.value == "hello" then true'

    event = %DtCore.Event{address: "1234", port: 10, value: "hello there", type: :an_atom, subtype: :another_atom}
    assert true == Rule.apply grammar, event, 'if event.value == "hello there" then true'
  end

  test "check returns atom" do
    grammar = Rule.load

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert :value == Rule.apply grammar, event, 'if event.value != "ciao" then value'
  end

  test "check structured rule" do
    grammar = Rule.load

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert :gotit == Rule.apply grammar, event, 'if event.value != "ciao" and event.value == "hello" then gotit'

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert nil == Rule.apply grammar, event, 'if event.value != "ciao" and event.value != "hello" then gotit'

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert :gotit == Rule.apply grammar, event, 'if event.value != "ciao" and (event.value != "hello" or event.value == "hello") then gotit'

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert :gotit == Rule.apply grammar, event, 'if event.value == "ciao" or event.value == "hello" then gotit'

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert :gotit == Rule.apply grammar, event, 'if event.value == "ciao" or (event.value != "hello" or event.value == "hello") then gotit'

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert :gotit == Rule.apply grammar, event, 'if (event.value == "ciao") or (event.value == "hello") then gotit'
  end

  test "check rule with param" do
    grammar = Rule.load

    event = %DtCore.Event{address: "1234", port: 10, value: "hello", type: :an_atom, subtype: :another_atom}
    assert {:gotit, '10'} == Rule.apply grammar, event, 'if (event.value == "ciao") or (event.value == "hello") then gotit(10)'
    assert {:gotit, 'ola'} == Rule.apply grammar, event, 'if (event.value == "ciao") or (event.value == "hello") then gotit(ola)'
  end

end

