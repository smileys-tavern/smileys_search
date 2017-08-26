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
	def posts_all(term, offset) do
		# infix search
	    search_for = "*" <> term <> "*"

	    result = Giza.query('postsummary_fast_index postsummary_slow_index', search_for)
	    	|> Giza.Query.offset(offset)
	    	|> Giza.send()
	    	# |> :giza_query.sort_extended('@weight + (voteprivate * 0.01)') NOT WORKING YET.. I think
	  	
	  	SmileysSearch.get_doc_ids(result)
	end

	@doc """
	Search posts given a map of params.  Compatible with GraphQL parameters
	"""
	def posts_all(%{s: search_for} = params) do
		result = Giza.query('postsummary_fast_index postsummary_slow_index', search_for)
			|> SmileysSearch.build_query_from_map(params)
			|> Giza.send()

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