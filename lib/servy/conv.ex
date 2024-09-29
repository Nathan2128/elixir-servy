defmodule Servy.Conv do
  defstruct method: "",
            path: "",
            params: %{},
            headers: %{},
            resp_content_type: " text/html",
            resp_body: "",
            status: nil
end
