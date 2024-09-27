defmodule Servy.BearController do
  alias Servy.Wildthings
  alias Servy.View

  def index(conv) do
    bears =
      Wildthings.list_bears()
      |> Enum.sort_by(& &1.name)

    View.render(conv, "index.eex", bears: bears)
  end

  def show(conv, %{"id" => id}) do
    bear = Wildthings.get_bear(id)

    View.render(conv, "show.eex", bear: bear)
  end

  def create(conv, %{"name" => name, "type" => type}) do
    %{conv | resp_body: "Created a #{type} bear named #{name}!", status: 201}
  end

  def delete(conv, _params) do
    %{conv | status: 403, resp_body: "Deleting a bear is forbidden!"}
  end
end
