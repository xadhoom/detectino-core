defmodule DtWeb.ReloadRegistry do
  @moduledoc """
  Registry used to send events from dt_web in order to
  dispatch reload actions when config is changed
  """
  def registry do
    :registry_core_reload
  end

  def key do
    :core_reload
  end
end