defmodule Detectino do
  use Application

  def start(_type, _args) do
    Detectino.start_link
  end

  def start_link do
    Detectino.Sup.start_link
  end

end
