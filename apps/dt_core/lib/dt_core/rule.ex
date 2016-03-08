defmodule DtCore.Rule do

  alias DtCore.Event

  require Logger

  def load do
    ABNF.load_file "priv/rules.abnf"
  end

  def apply(grammar, event, expression) when is_binary(expression) do
    _apply grammar, event, String.to_char_list(expression)
  end

  def apply(grammar, event, expression) when is_list(expression) do
    _apply grammar, event, expression
  end

  defp _apply(grammar, event = %Event{}, expression) do
    res = ABNF.apply grammar, "if-rule", expression, %{}
    values = Enum.at res.values, 0
    expression = values.code
    {value, _binding} = Code.eval_string expression, [event: event], __ENV__
    value
  end

end
