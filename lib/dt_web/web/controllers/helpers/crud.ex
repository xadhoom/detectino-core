defmodule DtWeb.CtrlHelpers.Crud do
  @moduledoc """
  Reusable helpers for creating CRUD apis
  """
  use Phoenix.Controller

  require Logger

  import Plug.Conn
  import Ecto.Query, only: [from: 2]

  #
  # XXX implement filtering (scoping) by relations id
  # also in delete, show, update...
  #

  @spec all(Plug.Conn.t, map, {module, module, [atom] | nil}, [atom]) ::
    {:ok, Plug.Conn.t, list} | {:error, Plug.Conn.t, pos_integer}
  def all(conn, params, {repo, model, sortdefs}, assocs \\ []) do
    filters = :fields
    |> model.__schema__
    |> build_filter(params)

    page = params
    |> Map.get("page", "1")
    |> String.to_integer

    per_page = params
    |> Map.get("per_page", "10")
    |> String.to_integer

    order_by = build_sorting_with_def(params, sortdefs)

    try do
      q = from m in model,
        limit: ^per_page,
        offset: ^((page - 1) * per_page),
        order_by: ^order_by,
        preload: ^assocs
      q = q |> add_query_filters(filters)
      items = repo.all(q)

      qc = from m in model,
        select: count(m.id)
      qc = qc |> add_query_filters(filters)
      total = repo.one(qc)

      total_s = total
      |> Integer.to_string

      conn = put_resp_header(conn, "x-total-count", total_s)

      links = links(conn, page, per_page, total)
      newconn = put_resp_header(conn, "link", links)

      {:ok, newconn, items}
    rescue
      Ecto.QueryError -> {:error, conn, 500}
    end
  end

  def links(conn, page, per_page, total) do
    next_p = nil

    float_p = (total / per_page)
    last_p = float_p
    |> Float.ceil
    |> trunc

    link = %ExLinkHeader{
      self: %ExLinkHeaderEntry{
        scheme: conn.scheme,
        host: conn.host,
        path: conn.request_path,
        params: %{per_page: per_page, page: page},
        attributes: %{total: total}
      },
      first: %ExLinkHeaderEntry{
        scheme: conn.scheme,
        host: conn.host,
        path: conn.request_path,
        params: %{per_page: per_page, page: 1}
      },
      last: %ExLinkHeaderEntry{
        scheme: conn.scheme,
        host: conn.host,
        path: conn.request_path,
        params: %{per_page: per_page, page: last_p}
      }
    }

    lh = if total > (page * per_page) do
      next_p = page + 1
      %ExLinkHeader{link | next: %ExLinkHeaderEntry{
          scheme: conn.scheme,
          host: conn.host,
          path: conn.request_path,
          params: %{per_page: per_page, page: next_p}
      }}
    else
      link
    end
    lh
    |> ExLinkHeader.build

  end

  def create(conn, params, module, repo, path_fn, assocs \\ []) do
    changeset = module.create_changeset(struct(module), params)

    case repo.insert(changeset) do
      {:ok, record} ->
        record = assocs
        |> Enum.reduce(record, fn(assoc, _acc) ->
          repo.preload(record, assoc)
        end)
        path = apply(DtWeb.Router.Helpers, path_fn, [conn, :show, record])
        conn = conn
                |> put_resp_header("location", path)
                |> put_status(201)
        {:ok, conn, record}
      {:error, changeset} -> {:error, conn, 400, changeset}
    end
  end

  def show(conn, id, module, repo) do
    case repo.get(module, id) do
      nil -> {:error, conn, 404}
      record -> {:ok, conn, record}
    end
  end

  def update(conn, params, repo, model) do
    case Map.get(params, "id") do
      :nil -> {:error, conn, 400}
      id ->
        case repo.get(model, id) do
          nil -> {:error, conn, 404}
          record ->
            record
            |> model.update_changeset(params)
            |> perform_update(repo, conn)
        end
    end
  end

  def delete(conn, params, repo, model) do
    case Map.get(params, "id") do
      id when is_binary(id) ->
        case repo.get(model, id) do
          nil -> {:error, conn, 404}
          record ->
            repo.delete!(record)
            {:response, conn, 204}
        end
      _ -> {:error, conn, 403}
    end
  end

  def delete(conn, _) do
    {:error, conn, 403}
  end

  defp build_sorting_with_def(params, nil) do
    case Map.get(params, "sort") do
      f when is_binary(f) ->
        field = String.to_existing_atom(f)
        dir = params |> Map.get("direction") |> dir_to_atom()
        Keyword.new([{dir, field}])
      nil ->
        []
    end
  end

  defp build_sorting_with_def(params, default) when is_list(default) do
    # right now we support only ordering by 1 field
    build_sorting_with_def(params, Enum.at(default, 0))
  end

  defp build_sorting_with_def(params, default) when is_atom(default) do
    field = case Map.get(params, "sort") do
      f when is_binary(f) ->
        String.to_existing_atom(f)
      nil ->
        default
    end

    dir = params |> Map.get("direction") |> dir_to_atom()

    Keyword.new([{dir, field}])
  end

  defp dir_to_atom(dir) do
    case dir do
      "asc" -> :asc
      "desc" -> :desc
      _ -> :asc
    end
  end

  defp build_filter(fields, params) do
    Enum.filter_map(params, fn({param, _value}) ->
      param_is_model_field?(param, fields)
    end,
    fn({param, value}) ->
      match = get_match_mode(params, param)
      {param, value, match}
    end)
  end

  defp param_is_model_field?(param, fields) do
    fields
    |> Enum.any?(fn(field) ->
      field = Atom.to_string(field)
      {:ok, regex} = Regex.compile("^" <> field <> "(?!.*MatchMode)")
      cond do
        String.match?(param, regex) -> true
        param == field -> true
        true -> false
      end
    end)
  end

  defp get_match_mode(params, field) do
    case Map.get(params, field <> "MatchMode", "equals") do
      "equals" -> :equals
      "contains" -> :contains
      "in" -> :in
      "starts" -> :starts
      "ends" -> :ends
      v ->
        Logger.error fn() ->
          "Invalid match mode #{inspect v}, falling back to default"
        end
        :equals
    end
  end

  defp perform_update(changeset, repo, conn) do
    case repo.update(changeset) do
      {:ok, record} ->
        conn = put_status(conn, 200)
        {:ok, conn, record}
      {:error, _changeset} ->
        {:error, conn, 400}
    end
  end

  defp add_query_filters(q, filters) do
    Enum.reduce(filters, q, fn({k, v, match}, query) ->
      case match do
        :contains ->
          new_v = "%" <> v <> "%"
          add_ilike(query, k, new_v)
        :starts ->
          new_v = v <> "%"
          add_ilike(query, k, new_v)
        :ends ->
          new_v = "%" <> v
          add_ilike(query, k, new_v)
        :equals ->
          add_equal(query, k, v)
      end
    end)
  end

  defp add_equal(query, key, value) do
    case String.contains?(key, ".") do
      false ->
        col = String.to_existing_atom(key)
        from q in query, where: field(q, ^col) == ^value
      true ->
        equal_jsonb_fragment(query, key, value)
    end
  end

  defp add_ilike(query, key, value) do
    case String.contains?(key, ".") do
      false ->
        col = String.to_existing_atom(key)
        from q in query, where: ilike(field(q, ^col), ^value)
      true ->
        ilike_jsonb_fragment(query, key, value)
    end
  end

  defp ilike_jsonb_fragment(query, field, value) do
    case String.split(field, ".") do
      [field, key] -> ilike_jsonb_fragment(query, field, key, value)
      [field, key1, key2] -> ilike_jsonb_fragment(query, field, key1, key2, value)
    end
  end

  defp ilike_jsonb_fragment(query, field, key, value) do
    field = String.to_existing_atom(field)
    from q in query, where: fragment("?->>? ILIKE ?", field(q, ^field), ^key, ^value)
  end

  defp ilike_jsonb_fragment(query, field, key1, key2, value) do
    field = String.to_existing_atom(field)
    from q in query, where: fragment("?->?->>? ILIKE ?", field(q, ^field), ^key1, ^key2, ^value)
  end

  defp equal_jsonb_fragment(query, field, value) do
    case String.split(field, ".") do
      [field, key] -> equal_jsonb_fragment(query, field, key, value)
      [field, key1, key2] -> equal_jsonb_fragment(query, field, key1, key2, value)
    end
  end

  defp equal_jsonb_fragment(query, field, key, value) do
    field = String.to_existing_atom(field)
    from q in query, where: fragment("?->>? = ?", field(q, ^field), ^key, ^value)
  end

  defp equal_jsonb_fragment(query, field, key1, key2, value) do
    field = String.to_existing_atom(field)
    from q in query, where: fragment("?->?->>? = ?", field(q, ^field), ^key1, ^key2, ^value)
  end

end
