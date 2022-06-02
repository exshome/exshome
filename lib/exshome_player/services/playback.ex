defmodule ExshomePlayer.Services.Playback do
  @moduledoc """
  Store playback state.
  """

  alias ExshomePlayer.Services.MpvSocket

  @spec load_url(url :: String.t()) :: MpvSocket.command_response()
  def load_url(url) when is_binary(url) do
    send_command(["playlist-clear"])
    send_command(["loadfile", url])
    play()
  end

  @spec play() :: MpvSocket.command_response()
  def play do
    set_property("pause", false)
  end

  @spec pause() :: MpvSocket.command_response()
  def pause do
    set_property("pause", true)
  end

  @spec set_volume(level :: integer()) :: MpvSocket.command_response()
  def set_volume(level) when is_number(level) do
    set_property("volume", level)
  end

  @spec seek(duration :: integer()) :: MpvSocket.command_response()
  def seek(time_pos) when is_number(time_pos) do
    send_command(["seek", time_pos, "absolute"])
  end

  @spec set_property(property :: String.t(), value :: term()) :: MpvSocket.command_response()
  def set_property(property, value) do
    send_command(["set_property", property, value])
  end

  defdelegate send_command(payload), to: MpvSocket
end
