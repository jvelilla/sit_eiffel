note
	description: "[
				application execution
			]"
	date: "$Date: 2016-10-21 10:45:18 -0700 (Fri, 21 Oct 2016) $"
	revision: "$Revision: 99331 $"

class
	EWF_APP_EXECUTION


inherit
	WSF_FILTERED_ROUTED_EXECUTION
		redefine
			initialize,
			clean
		end

	LOGGABLE

create
	make

feature {NONE} -- Initialization

	initialize
		do
			logger.write_debug ("------------------------> Starting Request -------------------------->")
			if not db_connection.is_connected then
				db_connection.connect
			end
			Precursor
		end

feature -- Access

	db_connection: DB_CONNECTION
		once
			create Result
		end

feature -- Filter

	create_filter
			-- Create `filter'
		do
				--| Example using Maintenance filter.
			create {WSF_MAINTENANCE_FILTER} filter
		end

	setup_filter
			-- Setup `filter'
		local
			l_filter: like filter
		do
			logger.write_debug ("Setting CORS filter")
			create {WSF_CORS_FILTER} l_filter
			l_filter.set_next (create {WSF_LOGGING_FILTER})

				--| Chain more filters like {WSF_CUSTOM_HEADER_FILTER}, ...
				--| and your owns filters.

			filter.append (l_filter)
		end


feature -- Router

	setup_router
			-- Setup `router'
		local
			fhdl: WSF_FILE_SYSTEM_HANDLER
			company_handler: COMPANY_HANDLER
			-- l_options_filter: WSF_CORS_OPTIONS_FILTER -- REMOVE ME
		do
				--| As example:
				--|   /doc is dispatched to self documentated page
				--|   /* are dispatched to serve files/directories contained in "www" directory

				--| Self documentation
			router.handle ("/api/doc", create {WSF_ROUTER_SELF_DOCUMENTATION_HANDLER}.make (router), router.methods_GET)

			  -- Add all handlers here so that their execute method can be called
			create company_handler.make (db_connection, router)

				--| Files publisher
			create fhdl.make_hidden ("www")
			fhdl.set_directory_index (<<"index.html">>)
			router.handle ("", fhdl, router.methods_GET)
		end

feature -- Cleaning

	clean
		do
			Precursor
			logger.write_debug ("Closing DB connection")
			logger.write_debug ("<--------- ENDING Request ---------------")
			db_connection.disconnect
		end


end
