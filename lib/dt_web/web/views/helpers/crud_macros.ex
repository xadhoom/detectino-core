defmodule DtWeb.CrudMacroView do

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :model, accumulate: false
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      def render("index.json", %{items: items}) do
        render_many(items, __MODULE__, "#{Atom.to_string @model}.json")
      end

      def render("show.json", %{item: item}) do
        render_one(item, __MODULE__, "#{Atom.to_string @model}.json")
      end

      def render("create.json", %{item: item}) do
        render_one(item, __MODULE__, "#{Atom.to_string @model}.json")
      end

      def render("update.json", %{item: item}) do
        render_one(item, __MODULE__, "#{Atom.to_string @model}.json")
      end

      def render(_, map) do
        {:ok, item} = Map.fetch map, @model
        item
        |> Map.from_struct
        |> Map.drop([:__meta__, :__struct__])
      end

    end
  end

end
