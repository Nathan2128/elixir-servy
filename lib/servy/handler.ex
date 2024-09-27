defmodule Servy.Handler do
  @moduledoc """
  Handles requests to server.
  """
  import Servy.Plugs
  alias Servy.Conv

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
    [top, params_string] = String.split(request, "\n\n")
    [request_line | headers] = String.split(top, "\n")
    [method, path, _version] = String.split(request_line, " ")
    params = parse_params(params_string)

    %Conv{method: method, path: path, params: params}
  end

  def parse_params(params_string) do
    params_string
    |> String.trim()
    |> URI.decode_query()
  end

  def route(%Conv{method: "GET", path: "/wildthings"} = conv) do
    %{conv | resp_body: "Bears, Lions, Tigers", status: 200}
  end

  def route(%Conv{method: "GET", path: "/bears"} = conv) do
    %{conv | resp_body: "Teddy, Smokey, Paddington", status: 200}
  end

  def route(%Conv{method: "GET", path: "/bears/" <> id} = conv) do
    %{conv | resp_body: "Bear #{id}", status: 200}
  end

  def route(%Conv{method: "POST", path: "/bears"} = conv) do
    %{
      conv
      | status: 201,
        resp_body: "Created a #{conv.params["type"]} bear named #{conv.params["name"]}!"
    }
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
    HTTP/1.1 #{conv.status} #{status_reason(conv.status)}
    Content-Type: text/html
    Content-Length: #{String.length(conv.resp_body)}

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
