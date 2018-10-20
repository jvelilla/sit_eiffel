note
	description: "Summary description for {DB_CONNECTION}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	DB_CONNECTION

inherit
	DATABASE_APPL [ODBC]

	FALLIBLE


feature -- Constants

	Datasource_name: STRING
		once
			Result := "PODBC"
		end

	Database_username: STRING
		once
			Result := "pgsqldbusr"
		end

	Database_password: STRING
		once
			Result := "17$psql/=07"
		end


feature -- access

	Stringlength: INTEGER = 80 --TODO: remove me if you can! unknown?

feature {NONE} -- Access for Database Operations

	session_control: detachable DB_CONTROL

	base_selection: detachable DB_SELECTION

	base_update: detachable DB_CHANGE

feature -- Database Connection

	disconnect
		require
			is_connected
		do
			if attached session_control as sc then
				sc.disconnect
				logger.write_information("DB Connection disconnected")
			else
				logger.write_error("Unable to disconnect, session_control is Void")
			end
		end

	is_connected: BOOLEAN
		do
			Result := attached session_control as sc and then sc.is_connected
		end

	connect
		do
			set_data_source(Datasource_name)

				-- Set user's name and password
			login (Database_username, Database_password)

				-- Initialization of the Relational Database:
				-- This will set various informations to perform a correct
				-- Connection to the Relational database
			set_base

				-- Create usefull classes
				-- 'session_control' provides informations control access and
				--  the status of the database.
				-- 'base_selection' provides a SELECT query mechanism.
				-- 'base_update' provides updating facilities.
			create session_control.make
			create base_selection.make
			create base_update.make

			if attached session_control as sc then
				sc.set_trace
			end
			if attached base_selection as bs then
				bs.set_trace
			end
			if attached base_update as bu then
				bu.set_trace
			end

				-- Start session
			if attached session_control as sc then
				sc.connect
				logger.write_information("DB Connection connected")
			else
				logger.write_error("Unable to connect to database, session_control is Void")
			end
		ensure
			is_connected
					-- Something went wrong, and the connection failed
--				session_control.raise_error
--				tmp_string.wipe_out
--				tmp_string.append ("exit")
--			end
		end


	manage_errors_and_warnings
			-- Manage errors and warnings that may have
			-- occurred during last operation.
		do
			if attached session_control as l_session_control then
				if l_session_control.is_ok then
						-- There was an error!
					l_session_control.raise_error
					l_session_control.reset
				else
					if l_session_control.warning_message_32.count /= 0 then
						logger.write_warning (l_session_control.warning_message_32)
					end
				end
			else
				set_last_error(create {ATTACHED_OBJECT_EXPECTED}.make ("session_control is Void"))
			end
		end

feature -- Status Report

	valid_for_modification: BOOLEAN
		do
			Result := attached base_selection
				and attached session_control
		end

	valid_for_select: BOOLEAN
		do
			Result := valid_for_modification
		end

	valid_resultset: BOOLEAN
		do
			Result := attached base_selection as l_bs
				and then attached l_bs.cursor
		end

	valid_base_selection: BOOLEAN
		do
			Result := attached base_selection
		end

	cursor: attached like base_selection.cursor
		require
			valid_resultset
		do
			create Result.make
			if attached base_selection as l_bs and then attached l_bs.cursor as l_curs then
				Result := l_curs
			else
				Check
					not_happening: False
				end
			end
		end

feature -- Status Setting

	set_action (an_action: ACTION)
		require
			valid_base_selection
		do
			if attached base_selection as l_bs then
				l_bs.set_action (an_action)
			-- else covered by require
			end
		end

feature -- Operations

	execute_query (a_query: STRING)
			-- calling start and execute
		do
			if attached base_selection as bs then
				bs.query (a_query)
				if bs.is_ok then
					bs.load_result -- calling start and execute
				else
					logger.write_critical ("Error while retreiving item from DB")
				end
				bs.terminate
			else
				create {ATTACHED_OBJECT_EXPECTED} last_error.make("Base_selection is void")
			end
		end

	execute_update (a_query: STRING)
		local
			l_msg: STRING
		do
			if attached base_update as l_bu then
				if l_bu.is_ok then
					l_bu.modify (a_query)
					l_msg := "Updated successfully"
				-- TODO: get and set the ID of newly created instance here
					if l_bu.is_affected_row_count_supported then
						l_msg.append ("modified:" + l_bu.affected_row_count.out)
					end
					set_last_success_message (l_msg)
				else
					set_last_error (create {ODBC_ERROR}.make("Error updating qry:" + a_query + "-msg:" + l_bu.error_message_32))
				end
			else
				set_last_error (create {ATTACHED_OBJECT_EXPECTED}.make("Base_selection is void"))
			end
		end

end
