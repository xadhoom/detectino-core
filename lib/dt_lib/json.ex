defmodule DtLib.Json do
  @moduledoc false

  def decode_as(input, to_struct) do
    case Jason.decode(input, keys: :atoms!) do
      {:ok, term} -> {:ok, struct(to_struct, filter_map(term))}
      err -> err
    end
  end

  def decode_as!(input, to_struct) do
    term = Jason.decode!(input, keys: :atoms!)
    struct(to_struct, term)
  end

  defp filter_map(term) do
    term
  end
end
