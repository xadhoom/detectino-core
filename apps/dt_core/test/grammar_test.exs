defmodule DtCore.GrammarTest do
  use ExUnit.Case, async: true

  test "check grammar validity" do
    ABNF.load_file "priv/rules.abnf"
  end

  test "check gt than rule" do
    grammar = ABNF.load_file "priv/rules.abnf"

    res = ABNF.apply grammar, "if-rule", 'IF event.value > 10 THEN what', %{} 
    values = Enum.at res.values, 0
    assert 'event.value' == values.lcond
    assert '10' == values.rcond
    assert 'what' == values.cons
    assert '>' == values.comp
    assert 'IF' == values.op
    assert 'THEN' == values.then
  end

  test "check invalid rule" do
    grammar = ABNF.load_file "priv/rules.abnf"
    res = ABNF.apply grammar, "if-rule", 'IF event.value > something', %{} 
    assert is_nil(res)
  end

  test "check different, equal rule" do
    grammar = ABNF.load_file "priv/rules.abnf"

    res = ABNF.apply grammar, "if-rule", 'IF event.value != "something" THEN what', %{} 
    refute is_nil(res)

    res = ABNF.apply grammar, "if-rule", 'IF event.value == "something" THEN what', %{} 
    refute is_nil(res)

    res = ABNF.apply grammar, "if-rule", 'IF event.value > "Something" THEN what', %{} 
    refute is_nil(res)
  end

  test "check string with space" do
    grammar = ABNF.load_file "priv/rules.abnf"
    res = ABNF.apply grammar, "if-rule", 'IF event.value == "something here" THEN what', %{} 
    refute is_nil(res)
  end


end

