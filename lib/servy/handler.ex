defmodule Servy.Handler do
  @moduledoc """
  Handles requests to server.
  """
  import Servy.Plugs

  alias Servy.Conv
  alias Servy.BearController
  alias Servy.VideoCam

  @pages_path Path.expand("pages", File.cwd!())

  @doc "Transforms a request into a response."
  def handle(request) do
    request
    |> parse()
    |> rewrite_path()
    |> log()
    |> route()
    |> track()
    |> format_response()
  end

  def parse(request) do
    [top, params_string] = String.split(request, "\r\n\r\n")
    [request_line | header_lines] = String.split(top, "\r\n")
    [method, path, _version] = String.split(request_line, " ")
    headers = parse_headers(header_lines)
    params = parse_params(headers["Content-Type"], params_string)

    IO.inspect(header_lines)
    %Conv{method: method, path: path, params: params, headers: headers}
  end

  def parse_headers(header_lines) do
    Enum.reduce(header_lines, %{}, fn line, headers ->
      [key, value] = String.split(line, ": ")
      Map.put(headers, key, value)
    end)
  end

  @doc """
  Parses the given param string of the form `key1=value1&key2=value2`
  into a map with corresponding keys and values.

  ## Examples
      iex> params_string = "name=Baloo&type=Brown"
      iex> Servy.Parser.parse_params("application/x-www-form-urlencoded", params_string)
      %{"name" => "Baloo", "type" => "Brown"}
      iex> Servy.Parser.parse_params("multipart/form-data", params_string)
      %{}
  """
  def parse_params("application/x-www-form-urlencoded", params_string) do
    params_string
    |> String.trim()
    |> URI.decode_query()
  end

  def parse_params(_content_type, _params_string) do
    %{}
  end

  def route(%Conv{method: "GET", path: "/sensors"} = conv) do
    task = Task.async(fn -> Servy.Tracker.get_location("bigfoot") end)

    snapshots =
      ["cam-1", "cam-2", "cam-3"]
      |> Enum.map(&Task.async(fn -> VideoCam.get_snapshot(&1) end))
      |> Enum.map(&Task.await/1)

    where_is_bigfoot = Task.await(task)

    %{conv | status: 200, resp_body: inspect({snapshots, where_is_bigfoot})}
  end

  def route(%Conv{method: "GET", path: "/hibernate/" <> time} = conv) do
    time |> String.to_integer() |> :timer.sleep()

    %{conv | status: 200, resp_body: "Awake!"}
  end

  def route(%Conv{method: "GET", path: "/wildthings"} = conv) do
    %{conv | resp_body: "Bears, Lions, Tigers", status: 200}
  end

  def route(%Conv{method: "GET", path: "/api/bears"} = conv) do
    Servy.Api.BearController.index(conv)
  end

  def route(%Conv{method: "GET", path: "/bears"} = conv) do
    BearController.index(conv)
  end

  def route(%Conv{method: "GET", path: "/bears/" <> id} = conv) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end

  def route(%Conv{method: "POST", path: "/bears"} = conv) do
    BearController.create(conv, conv.params)
  end

  def route(%{method: "DELETE", path: "/bears/" <> _id} = conv) do
    BearController.delete(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/about"} = conv) do
    @pages_path
    |> Path.join("about.html")
    |> File.read()
    |> handle_file(conv)
  end

  def route(%Conv{method: _method, path: path} = conv) do
    %{
      conv
      | resp_body: "The path #{path} was not found on this server.",
        status: 404
    }
  end

  def handle_file({:ok, content}, conv) do
    %{conv | status: 200, resp_body: content}
  end

  def handle_file({:error, :enoent}, conv) do
    %{conv | status: 404, resp_body: "File not found!"}
  end

  def handle_file({:error, reason}, conv) do
    %{conv | status: 500, resp_body: "File error: #{reason}"}
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{conv.status} #{status_reason(conv.status)}\r
    Content-Type:#{conv.resp_content_type}\r
    Content-Length: #{String.length(conv.resp_body)}\r
    \r
    #{conv.resp_body}
    """
  end

  defp status_reason(code) do
    %{
      200 => "OK",
      201 => "Created",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      500 => "Internal Server Error"
    }[code]
  end
end
