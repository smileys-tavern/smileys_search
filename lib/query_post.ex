defmodule SmileysSearch.QueryPost do
	@doc """
	Search posts filtered to a single room
	"""
	def posts_by_room(term, offset, room) do
		# infix search
	    search_for = "*" <> term <> "*"

	    result = Giza.query('postsummary_fast_index postsummary_slow_index', search_for)
	    	|> Giza.Query.offset(offset)
	    	|> Giza.Query.filter_include("room", [room])
	    	|> Giza.send()
	  	
	  	SmileysSearch.get_doc_ids(result)
	end

	@doc """
	Search posts site-wide
	"""
	def posts_all(search_for, offset) do
	    result = Giza.SphinxQL.new()
	    	|> Giza.SphinxQL.select("*")
	    	|> Giza.SphinxQL.from("postsummary_fast_index, postsummary_slow_index")
	    	|> Giza.SphinxQL.limit(25)
	    	|> Giza.SphinxQL.offset(offset)
	    	|> Giza.SphinxQL.match(search_for)
	    	|> Giza.Service.sphinxql_send()

	    {:ok, meta} = Giza.SphinxQL.meta()

	    total_returned = String.to_integer(meta.total_found)

	  	case Giza.get_doc_ids(result) do
	  		{:ok, doc_ids} ->
	  			filtered_doc_ids = Enum.take(doc_ids, 25)
	  			{:ok, filtered_doc_ids, total_returned}
	  		error ->
	  			error
	  	end
	end

	@doc """
	Search posts given a map of params.  Compatible with GraphQL parameters
	"""
	def posts_all(%{s: search_for} = params) do
		result = Giza.query('postsummary_fast_index postsummary_slow_index', search_for)
			|> SmileysSearch.build_query_from_map(params)
			|> Giza.Service.send()

		SmileysSearch.get_doc_ids(result)
	end

	@doc """
	Search posts given a map that can be translated into sphinx ready inputs
	"""
	def posts_by_map(%{s: search_for} = params) do
		result = Giza.query('postsummary_fast_index postsummary_slow_index', search_for)
			|> SmileysSearch.build_query_from_map(params)
			|> Giza.send()

		SmileysSearch.get_doc_ids(result)
	end
end