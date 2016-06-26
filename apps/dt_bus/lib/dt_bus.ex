defmodule DtBus do
  @moduledoc """
  DtBus application entry point
  """

  use Application

  def start(_type, _args) do
    __MODULE__.start_link
  end

  def start_link do
    __MODULE__.CanSup.start_link
  end

end
