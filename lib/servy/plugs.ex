defmodule Servy.Plugs do
  require Logger

  @doc "Logs a warning if the path is not found."
  def track(%{status: 404, path: path} = conv) do
    Logger.warning("Warning: #{path} is on the loose!")

    conv
  end

  def track(conv), do: conv

  def rewrite_path(%{path: "/wildlife"} = conv) do
    %{conv | path: "/wildthings"}
  end

  def rewrite_path(conv), do: conv

  def log(conv) do
    Logger.info(conv)

    conv
  end
end
