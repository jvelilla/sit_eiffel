note
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2011-05-08 06:23:31 -0700 (Sun, 08 May 2011) $"
	revision: "$Revision: 86398 $"

class ESQL

inherit
	LOGGABLE
		rename
			make as make_from_loggable
		end

create
	make


feature -- Access

	db_connection: DB_CONNECTION
	company_service: COMPANY_SERVICE

feature {NONE} -- Initialization

	make
			-- Start SQL_MONITOR
		local
			l_companies: like company_service.last_items -- LINKED_LIST[COMPANY]
		do
			make_from_loggable
			logger.write_debug ("-----> Starting application")
			create db_connection.make
			db_connection.set_database_connection
			create company_service.make (db_connection)
			company_service.load_all
			l_companies := company_service.last_items
			-- old_main_loop
			db_connection.unset_database_connection
		end

--feature {NONE}

--		old_main_loop
--			local
--				tmp_string: detachable STRING
--			do
--					-- Main loop of the monitor
--				from
--					tmp_string := ""
--				until
--						-- Terminate?
--					tmp_string.is_equal ("exit") or
--					io.input.end_of_file
--				loop
--					read_order
--					if io.input.end_of_file then
--						tmp_string := "exit"
--					else
--						tmp_string := io.laststring
--					end
--					check tmp_string /= Void end -- implied by previous if clause and `read_order' postcondition
--					if is_select_statement (tmp_string) then
--							-- The query is a SELECT, so we have to use
--							-- DB_SELECTION.query
--						base_selection.query (tmp_string)
--						if session_control.is_ok then
--								-- Iterate through resulting data,
--								-- and display them
--							base_selection.load_result
--						else
--							manage_errors_and_warnings
--						end
--						base_selection.terminate
--					elseif not tmp_string.is_equal ("exit") then
--							-- The user updates the database
--						base_update.modify (tmp_string)
--					end
--					manage_errors_and_warnings
--				end

--			end

--	read_order
--			-- Get statement from standard input
--		do
--			io.putstring ("SQL> ")
--			io.readline
--		end

note
	copyright:	"Copyright (c) 1984-2006, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			 Eiffel Software
			 356 Storke Road, Goleta, CA 93117 USA
			 Telephone 805-685-1006, Fax 805-685-6869
			 Website http://www.eiffel.com
			 Customer support http://support.eiffel.com
		]"

end
