defmodule DtCore.GrammarTest do
  use ExUnit.Case, async: true

  test "check grammar validity" do
    ABNF.load_file "priv/rules.abnf"
  end

  test "check gt than rule" do
    grammar = ABNF.load_file "priv/rules.abnf"

    res = ABNF.apply grammar, "if-rule", 'IF event.value > "10" THEN what', %{}
    values = Enum.at res.values, 0
    assert 'if event.value > "10" do :what end' == values.code
  end

  test "check invalid rule" do
    grammar = ABNF.load_file "priv/rules.abnf"
    res = ABNF.apply grammar, "if-rule", 'IF event.value > something', %{} 
    assert is_nil(res)
  end

  test "atoms in condition" do
    grammar = ABNF.load_file "priv/rules.abnf"

    res = ABNF.apply grammar, "if-rule", 'IF event.value != something THEN what', %{} 
    refute is_nil(res)

    res = ABNF.apply grammar, "if-rule", 'IF event.value != an_atom THEN what', %{} 
    refute is_nil(res)
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

  test "check complex condition" do
    grammar = ABNF.load_file "priv/rules.abnf"
    res = ABNF.apply grammar, "if-rule", 'IF event.value == "something here" AND event.value > 10 THEN what', %{} 
    refute is_nil(res)
  end

  test "check longer complex condition" do
    grammar = ABNF.load_file "priv/rules.abnf"
    res = ABNF.apply grammar, "if-rule", 'IF event.value == "something here" AND event.value > 10 OR event.value < 8 THEN what', %{} 
    refute is_nil(res)

    res = ABNF.apply grammar, "if-rule", 'IF event.value == "something here" OR event.value > 10 AND event.value < 8 THEN what', %{} 
    refute is_nil(res)
  end

  test "check wrapped condition" do
    grammar = ABNF.load_file "priv/rules.abnf"
    res = ABNF.apply grammar, "if-rule", 'IF (event.value == "something here") THEN what', %{} 
    refute is_nil(res)
  end

  test "check complex, nested condition" do
    grammar = ABNF.load_file "priv/rules.abnf"
    res = ABNF.apply grammar, "if-rule", 'IF event.value == "something here" AND (event.value > 10 OR event.value < 10) THEN what', %{} 
    refute is_nil(res)
  end

  test "check rule with result with variable" do
    grammar = ABNF.load_file "priv/rules.abnf"
    res = ABNF.apply grammar, "if-rule", 'IF event.value == "something here" AND (event.value > 10 OR event.value < 10) THEN what(20)', %{} 
    value = Enum.at res.values, 0
    assert value.param == '20'
  end

end

