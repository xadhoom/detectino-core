defmodule Dt.Bus do
  use Application

  def start(_type, _args) do
    __MODULE__.start_link
  end

  def start_link do
    __MODULE__.Sup.start_link
  end

end
