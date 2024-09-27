defmodule Servy.Plugs do
  alias Servy.Conv

  require Logger

  @doc "Logs a warning if the path is not found."
  def track(%Conv{status: 404, path: path} = conv) do
    Logger.warning("Warning: #{path} is on the loose!")

    conv
  end

  def track(%Conv{} = conv), do: conv

  def rewrite_path(%Conv{path: "/wildlife"} = conv) do
    %{conv | path: "/wildthings"}
  end

  def rewrite_path(%Conv{} = conv), do: conv

  def log(%Conv{} = conv) do
    Logger.info(conv)

    conv
  end
end
