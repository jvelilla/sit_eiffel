note
	description: "Summary description for {SIT_HANDLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIT_HANDLER[G -> DB_ENTITY, H -> DB_SERVICE[G] create make end]

inherit
	WSF_FILTER

	WSF_URI_TEMPLATE_HANDLER

	WSF_RESOURCE_HANDLER_HELPER
		redefine
			do_get,
			do_post,
			do_put,
			do_delete
		end

	REFACTORING_HELPER

	WSF_SELF_DOCUMENTED_HANDLER

	LOGGABLE

feature {NONE} -- Initialize

	make (a_db_connection: DB_CONNECTION; a_router: WSF_ROUTER)
		do
			db_connection := a_db_connection
			router := a_router
			create db_service.make (a_db_connection)
		end

	set_handler
		-- Setting the methods this service will answer to
		-- based on https://stackoverflow.com/questions/256349/what-are-the-best-common-restful-url-verbs-and-actions/256359#256359 and https://stackoverflow.com/questions/630453/put-vs-post-in-rest
		require
			setted_router: attached router
		local
			l_options_filter: WSF_CORS_OPTIONS_FILTER
			l_http_methods: WSF_REQUEST_METHODS
			l_url, l_s: STRING
		do
			create l_options_filter.make (router)
			l_options_filter.set_next (Current)

			-- Adds the handler for '/'
			create l_http_methods
			l_http_methods.enable_options
			l_http_methods.enable_get
			l_http_methods.enable_post -- to create, modify and update (NOT CREATE), only on a url/object/ request
			l_url := api_base_url
			logger.write_debug (class_for_logger + "->Listening to URL:" + l_url)
			router.handle (api_base_url, create {WSF_URI_TEMPLATE_AGENT_HANDLER}.make (agent l_options_filter.execute), l_http_methods)
			-- Adds handler for '/{id}'
			create l_http_methods
			l_http_methods.enable_options
			l_http_methods.enable_get
			l_http_methods.enable_delete
			l_http_methods.enable_put -- create a resource(I'll choose only the post option for that on the client side), or overwrite it (idempotent), Post method will be an error here
			l_url := api_entity_by_id_url
			logger.write_debug (class_for_logger + "->Listening to URL:" + l_url)
			router.handle (l_url, create {WSF_URI_TEMPLATE_AGENT_HANDLER}.make (agent l_options_filter.execute), l_http_methods) -- as {parameter_name} is said, the attached {WSF_STRING} req.path_parameter ("parameter_name") will contain the value

			if ({G}).conforms_to ({CHILD_DB_ENTITY}) then
				-- Adds handler for '/children/{id}'
				create l_http_methods
				l_http_methods.enable_options
				l_http_methods.enable_get
				l_s := ({G}).out
				l_s.to_lower
				l_url := api_base_url + "/" + l_s + "/{id}"
				logger.write_debug (class_for_logger + "->Listening to URL:" + l_url)
				router.handle (l_url, create {WSF_URI_TEMPLATE_AGENT_HANDLER}.make (agent l_options_filter.execute), l_http_methods) -- as {parameter_name} is said, the attached {WSF_STRING} req.path_parameter ("parameter_name") will contain the value
			end
		end

feature -- Execute

	execute (a_request: WSF_REQUEST; a_response: WSF_RESPONSE)
			-- Execute request handler
		local
			l_msg: WSF_CORS_OPTIONS_RESPONSE
		do
			if a_request.is_request_method ({HTTP_REQUEST_METHODS}.method_options) then
				logger.write_debug ("Option request")
				create l_msg.make (a_request, router)
				a_response.send (l_msg)
			else
				logger.write_debug ("Other methods, executing them")
				execute_methods (a_request, a_response)
				execute_next (a_request, a_response)
			end
		end


feature -- Documentation

	mapping_documentation (m: WSF_ROUTER_MAPPING; a_request_methods: detachable WSF_REQUEST_METHODS): WSF_ROUTER_MAPPING_DOCUMENTATION
			-- TODO: Review me
		do
			create Result.make (m)
			if a_request_methods /= Void then
				if a_request_methods.has_method_post then
					Result.add_description ("URI:/tasks METHOD: POST GET")
				elseif a_request_methods.has_method_get
						or a_request_methods.has_method_put
						or a_request_methods.has_method_delete then
					Result.add_description ("URI:/" + api_base_url + "/{" + {DB_ENTITY}.Primary_key_db_column_name + "} METHOD: GET, PUT, DELETE")
				end
			end
		end

feature -- Constants

	Json_base_items_response: STRING = "[
						[$items]
				]"


	Json_base_item_response : STRING_32 = "[
						{"content" : $item }
					]"


feature -- Status report

	db_connection: DB_CONNECTION

	db_service: H

	router: WSF_ROUTER

	api_base_url: STRING
		  -- /class_name_lowercase
		local
			l_res: STRING
		once
			l_res := ({like item_prototype}).out
			l_res.to_lower
			Result := "/" + l_res
		end

	api_entity_by_id_url: STRING
		once
			Result := api_base_url + "/" + {DB_ENTITY}.Primary_key_db_column_name
		end

feature -- Items

	item_prototype: detachable G

feature -- HTTP Methods

	do_get (a_request: WSF_REQUEST; a_response: WSF_RESPONSE)
			-- <Precursor>
			-- to create, modify and update (NOT CREATE), only on a url/object/ request
		require else
			empty_service_error: not db_service.has_error
		do
			if request_has_primary_key_parameter (a_request) then -- Get by id
				logger.write_debug ("do_get-> With Id")
				if request_has_valid_primary_key (a_request) then
					db_service.load_from_primary_key (primary_key_from_request (a_request))
					if attached db_service.last_error as l_error then
						finalize_response_with_error (a_request, a_response, l_error )
						db_service.wipe_last_error
					else
						compute_response_get (a_request, a_response, db_service.item)
					end
				elseif attached {WSF_STRING} a_request.path_parameter ("id") as l_id then
					finalize_response_with_error (a_request, a_response, create {INVALID_REQUEST}.make("Invalid request, your parameter doesn't seem to be an integer:" + l_id.out) )
				else
					check
						shouldn_t_reach_here: False
					end
				end
			else -- Get all
				logger.write_debug ("do_get-> no Id -> getAll")
				db_service.load_all
				compute_response_get_all (a_request, a_response, db_service.items)
			end
		ensure then
			wiped_service_error: not db_service.has_error
		end

	do_post (a_request: WSF_REQUEST; a_response: WSF_RESPONSE)
			-- to create, modify and update, only on a url/object/ request
		require else
			empty_service_error: not db_service.has_error
		do
			compute_response_post (a_request, a_response)
		ensure then
			wiped_service_error: not db_service.has_error
		end

	do_put (a_request: WSF_REQUEST; a_response: WSF_RESPONSE)
			-- Updating a resource with PUT
			-- /{id} and request as json
		require else
			empty_service_error: not db_service.has_error
		do
			if request_has_primary_key_parameter (a_request) then
				logger.write_debug ("do_put-> With primary_key")
				if request_has_valid_primary_key (a_request) then -- update
					db_service.update_entity (primary_key_from_request (a_request), retrieve_data (a_request))
					if attached db_service.last_error as l_error then
						finalize_response_with_error (a_request, a_response, l_error )
						db_service.wipe_last_error
					else
						if attached db_service.last_success_message as l_msg then
							finalize_response_put (a_request, a_response)
						-- else covered by FALLIBLE class invariant
						end
						db_service.wipe_last_success_message
					end
				elseif attached {WSF_STRING} a_request.path_parameter ({DB_ENTITY}.Primary_key_db_column_name) as l_pk then -- error
					finalize_response_with_error (a_request, a_response, create {INVALID_REQUEST}.make("Invalid request, your parameter doesn't seem to be an integer:" + l_pk.out) )
				else
					check
						shouldn_t_reach_here: False
					end
				end
			else
				finalize_response_with_error (a_request, a_response, create {INVALID_REQUEST}.make("Invalid request, your parameter is not recognized") )
			end
		ensure then
			wiped_service_error: not db_service.has_error
		end

	do_delete (a_request: WSF_REQUEST; a_response: WSF_RESPONSE)
		require else
			empty_service_error: not db_service.has_error
		do
			if request_has_primary_key_parameter (a_request) then
				logger.write_debug ("do_delete-> With primary_key")
				if request_has_valid_primary_key (a_request) then
					db_service.delete_entity (primary_key_from_request (a_request))
					if attached db_service.last_error as l_error then
						finalize_response_with_error (a_request, a_response, l_error )
						db_service.wipe_last_error
					else
						if attached db_service.last_success_message as l_msg then
							finalize_response_delete (a_request, a_response)
--							finalize_response (l_msg, {HTTP_STATUS_CODE}.ok, a_request, a_response, False)
						-- else covered by FALLIBLE class invariant
						end
						db_service.wipe_last_success_message
					end
				elseif attached {WSF_STRING} a_request.path_parameter ({DB_ENTITY}.Primary_key_db_column_name) as l_pk then
					finalize_response_with_error (a_request, a_response, create {INVALID_REQUEST}.make("Invalid request, your parameter doesn't seem to be an integer:" + l_pk.out) )
				else
					check
						shouldn_t_reach_here: False
					end
				end
			else
				finalize_response_with_error (a_request, a_response, create {INVALID_REQUEST}.make("Invalid request, your parameter is not recognized") )
			end
		ensure then
			wiped_service_error: not db_service.has_error
		end

feature{NONE} -- Response Computing

	compute_response_get (a_request: WSF_REQUEST; a_response: WSF_RESPONSE; item: detachable like db_service.item)
			-- Resource not found if item is Void
		local
			l_to_put_string: STRING
		do
			create l_to_put_string.make_from_string (json_base_item_response)
			if attached item and then -- Item found
					attached item.to_json as l_json and then
					attached l_json.representation as l_json_repr then
				a_response.set_status_code ({HTTP_STATUS_CODE}.ok)
				create l_to_put_string.make_from_string (json_base_item_response)
				l_to_put_string.replace_substring_all ("$item", l_json_repr)
				finalize_response (l_to_put_string, {HTTP_STATUS_CODE}.ok, a_request, a_response, True)
			else
				check
					should_not_reach: False -- test is done by caller with last_error check and invariant of DB_ENTITY class
				end
			end
		end

	compute_response_get_all (a_request: WSF_REQUEST; a_response: WSF_RESPONSE; items: like db_service.items)
			-- With given items formats the response message
		require
			valid_db_service: db_service.ready_for_select
		local
			l_to_put_string, l_items_as_string: STRING
		do
			create l_items_as_string.make_empty
			across
				items as entity
			loop
				if attached entity.item as l_entity_item and then
					attached l_entity_item.to_json as l_entity_json and then
					attached l_entity_json.representation as l_entity_json_string then
					l_items_as_string.append (l_entity_json_string)
					if entity.cursor_index <= entity.last_index then
						l_items_as_string.append (",")
					end
				else
					logger.write_error("entity as json failed because of Void")
				end
			end

			create l_to_put_string.make_from_string (json_base_items_response)
			l_to_put_string.replace_substring_all ("$items", l_items_as_string)

			finalize_response (l_to_put_string, {HTTP_STATUS_CODE}.ok, a_request, a_response, True)
		end

	compute_response_post (a_request: WSF_REQUEST; a_response: WSF_RESPONSE)
			-- to create, modify and update, only on a url/object/ request
		require
			valid_db_service: not attached db_service.last_error -- last error was not cleaned
		local
			l_response_s: STRING
			l_status_code: like {HTTP_STATUS_CODE}.created
		do
			l_response_s := ""
			db_service.create_or_update_entity (retrieve_data(a_request))
			if attached db_service.last_error as l_err then
				finalize_response_with_error (a_request, a_response, l_err)
				db_service.wipe_last_error
			else
				if attached db_service.item as l_item then
					l_status_code := {HTTP_STATUS_CODE}.created
					l_response_s := l_item.to_json_string
				else
					finalize_response_with_error (a_request, a_response, create {ATTACHED_OBJECT_EXPECTED}.make ("compute_response_post got a problem"))
					db_service.wipe_last_error
				end
			end
		end

feature {NONE} -- URI helper methods

	finalize_response_with_error (a_request: WSF_REQUEST; a_response: WSF_RESPONSE; an_error: SIT_ERROR)
		local
			l_header: HTTP_HEADER
		do
			create l_header.make
			l_header.put_content_length (an_error.out.count)
			if attached a_request.request_time as time then
				l_header.put_utc_date (time)
			end
			l_header.put_content_type_text_plain
			a_response.set_status_code (an_error.http_status_code)
			a_response.put_header_text (l_header.string)
			a_response.put_string (an_error.out)
		end

	finalize_response (a_response_s: STRING; a_status_code: like {HTTP_STATUS_CODE}.ok; a_request: WSF_REQUEST; a_response: WSF_RESPONSE; a_response_is_json: BOOLEAN)
			--Either json or plain
		local
			l_http_header: HTTP_HEADER
		do
			create l_http_header.make
			l_http_header.add_header ("Cache-Control: max-age=0,must-revalidate") -- in seconds
			l_http_header.put_content_length (a_response_s.count)
			if attached a_request.request_time as time then
				l_http_header.put_utc_date (time)
			end
			if a_response_is_json then
				l_http_header.put_content_type_application_json
			else
				l_http_header.put_content_type_text_plain
			end
			a_response.set_status_code (a_status_code)
			a_response.put_header_text (l_http_header.string)
			a_response.put_string (a_response_s)
		end

	finalize_response_put (a_request: WSF_REQUEST; a_response: WSF_RESPONSE)
		do
			finalize_response_delete (a_request, a_response)
		end

	finalize_response_delete (a_request: WSF_REQUEST; a_response: WSF_RESPONSE)
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type_application_json
			if attached a_request.request_time as time then
				h.put_utc_date (time)
			end
			a_response.set_status_code ({HTTP_STATUS_CODE}.no_content)
			a_response.put_header_text (h.string)
		end

	primary_key_from_request (a_request: WSF_REQUEST): INTEGER_64
		require
			request_has_valid_primary_key (a_request)
		do
			if attached {WSF_STRING} a_request.path_parameter ({DB_ENTITY}.Primary_key_db_column_name) as l_pk and then l_pk.is_integer then
				Result := l_pk.value.to_integer_64
			end
		end

	request_has_valid_primary_key (a_request: WSF_REQUEST): BOOLEAN
		require
			valid_request: attached a_request.path_info
		do
			Result := request_has_primary_key_parameter (a_request)
				and attached {WSF_STRING} a_request.path_parameter ({DB_ENTITY}.Primary_key_db_column_name) as l_pk
				and then l_pk.is_integer
		end

	request_has_primary_key_parameter (a_request: WSF_REQUEST): BOOLEAN
		do
			Result := attached {WSF_STRING} a_request.path_parameter ({DB_ENTITY}.Primary_key_db_column_name)
		end


end
