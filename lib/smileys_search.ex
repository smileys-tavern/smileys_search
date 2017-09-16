defmodule SmileysSearch do
  @moduledoc """
  Provides an interface and helper methods to query and parse from Smileys Sphinx Search service.
  """

  @doc """
  Build upon a query using map arguments. Useful for API's that want many search query options available.

  ## Examples

      iex> SmileysSearch.build_query_from_map(query, )
      :world

  """
  def build_query_from_map(query, params) do
    case params do
      %{limit: limit} ->
        build_query_from_map(query |> Giza.Query.limit(limit), Map.delete(params, :limit))
      %{offset: offset} ->
        build_query_from_map(query |> Giza.Query.offset(offset), Map.delete(params, :offset))
      %{filter_include: filter_include} ->
        new_query = build_query_from_param_multi(query, filter_include, :filter_include)
        build_query_from_map(new_query, Map.delete(params, :filter_include))
      %{filter_exclude: filter_exclude} ->
        new_query = build_query_from_param_multi(query, filter_exclude, :filter_exclude)
        build_query_from_map(new_query, Map.delete(params, :filter_exclude))
      %{field_weights: field_weights} ->
        case field_weights do
          [_|_] ->
            format_field_weights = List.foldl(field_weights, [], fn(x, acc) -> 
              [field] = Map.keys(x)
              [{Atom.to_charlist(field), Map.get(x, field)}|acc] 
            end)

            build_query_from_map(query |> Giza.Query.field_weights(format_field_weights), Map.delete(params, :field_weights))
          _ ->
            build_query_from_map(query, Map.delete(params, :field_weights))
        end
      %{} ->
        query
    end
  end

  @doc """
  Helper method to build up a query based on a search param that should or could contain multiple inputs such as a range or list of keys

  ## Examples

      iex> SmileysSearch.build_query_from_param_multi(query, ..., ...)
  """
  def build_query_from_param_multi(query, param, method) do
    case param do
      [%{} = val|tail] ->
        val_list = Map.to_list(val)

        case val_list do
          [{param_key, %{:min => range1, :max => range2}}] ->
            {param_key_format, _} = String.split_at(Atom.to_string(param_key), -6)
            build_query_from_param_multi(apply(Giza.Query, method, [query, String.to_charlist(param_key_format), range1, range2]), tail, method)
          [{param_key, param_val}] ->
            build_query_from_param_multi(apply(Giza.Query, method, [query, Atom.to_charlist(param_key), param_val]), tail, method)
        end
      
      [] ->
        query
      _ ->
        # if method called correctly, should never be reached
        query
    end
  end

  @doc """
  Takes a giza result from a search and returns a list of the document id's

  ## Examples

      iex> SmileysSearch.get_doc_ids(giza_result)
      {:ok, [1, 5, 6, 7], 4}
  """
  def get_doc_ids(giza_result) do
    case giza_result do
      {:ok, %{matches: matches, total: total}} ->
        {:ok, get_doc_ids(matches, []), total}
      {:error, error} ->
        {:error, error}
    end
  end

  defp get_doc_ids([], accum) do
    Enum.uniq accum
  end

  defp get_doc_ids([query_attr|tail], accum) do
    {doc_id, _} = query_attr
    new_accum = [doc_id|accum]
    get_doc_ids(tail, new_accum)
  end
end
