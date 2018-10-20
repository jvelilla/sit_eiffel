note
	description: "Summary description for {DB_SERVICE}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	DB_SERVICE [G -> DB_ENTITY create default_create, make_from_db_service, make_from_json end]

inherit
	ACTION
		redefine
			start,
			execute
		end

	FALLIBLE
		redefine
			set_last_error,
			set_last_error_from_fallible
		end

feature {NONE} -- Creation

	make (a_db_connection: attached DB_CONNECTION)
		require
			valid_db_connection: a_db_connection.is_connected
		do
			db_connection := a_db_connection
			create items.make (100)
			create last_column_names.make
			create item_prototype
			db_connection.set_action (current)
		ensure
			db_connection_setted: a_db_connection = db_connection and db_connection.is_connected
		end

feature -- Access

	item: detachable G

	item_prototype: attached like item

	db_connection: DB_CONNECTION

	last_column_names: LINKED_LIST [STRING] -- Column names of last resultset (check if empty not if Void we are on Eiffel!...)

	items: HASH_TABLE [like item, INTEGER_64] -- content of last resultset and ids

	cursor: like db_connection.cursor
		do
			Result := db_connection.cursor
		end

feature -- status_report

	item_class_name: STRING
		once
			Result := ({attached like item}).out
		end

	item_table_name: STRING
		once
			Result := ({attached like item}).out
			Result.to_lower
		end

	ready_for_select, ready_for_update: BOOLEAN
		do
			Result := not has_error
		end

feature -- Status setting

	load_all
			-- Will make all items available into items
		local
			l_db_result: DB_RESULT
			l_qry: STRING
		do
			db_connection.execute_query (select_all_query)
			if db_connection.has_error then
				logger.write_critical ("Error while retreiving " + item_prototype.generating_type.out + " from DB")
				set_last_error_from_fallible (db_connection)
				db_connection.wipe_last_error
			end
		end

	load_from_primary_key (primary_key_v: INTEGER_64)
			-- Loads given item into item otherwise item will be Void
			-- 	last_error will give a feedback of success or failure
		require
			attached db_connection.valid_for_select
		local
			l_new_item, just_void: detachable like item
		do
			wipe_last_items
			db_connection.execute_query (select_query_from_primary_key_query (primary_key_v))
			if db_connection.has_error then
				set_last_error_from_fallible (db_connection)
				db_connection.wipe_last_error
			else
				create l_new_item.make_from_db_service (Current)
				if l_new_item.has_error then
					set_last_error_from_fallible (l_new_item)
					l_new_item := just_void
				else
					item := l_new_item
				end
			end
			item := l_new_item
		ensure
			valid_item: attached item as it implies it.primary_key = primary_key_v
		end

	create_or_update_entity (a_json_string: STRING)
			-- Put it in item if created otherwise item will be Void
			-- Working with item and modifying it
		require
			valid_db_connection: db_connection.valid_for_modification
		local
			l_void: like item
		do
			create item.make_from_json (a_json_string)
			if attached item as l_item and then l_item.has_error then
				set_last_error_from_fallible (l_item)
			else
				create_or_update_entity_impl (a_json_string)
			end
		end

	update_entity ( a_primary_key: like {DB_ENTITY}.primary_key; a_json_string: STRING)
			-- Put it in item if created otherwise item will be Void
			-- Working with item and modifying it
		require
			valid_db_connection:db_connection.valid_for_modification
		local
			l_void: like item
			l_msg: like {SIT_ERROR}.message
		do
			create item.make_from_json (a_json_string)
			if attached item as l_item then
				check
					valid_item_between_request_param_and_json_object: a_primary_key.is_equal (l_item.primary_key)
				end
				if l_item.has_error then
					set_last_error_from_fallible (l_item)
				else
					db_connection.execute_update (update_query)
						-- TODO: get and set the ID of newly created instance here
					if db_connection.has_error then
						l_msg := "last update did not work with json:" + a_json_string
						if attached db_connection.last_error as l_err then
							l_msg.append("-error:" + l_err.message)
						end
						set_last_error(create {UPDATE_ERROR}.make (l_msg))
					else
						set_last_success_message ("Entity updated into DB successfully")
					end
				end
				--else covered by require
			end
		end

	delete_entity (a_primary_key: INTEGER_64)
			-- Delete from given primary_key object
		require
			valid_db_connection: db_connection.valid_for_modification
		local
			l_void: like item
			l_msg: STRING
		do
			db_connection.execute_update (delete_query_from_primary_key_query(a_primary_key))
			if db_connection.has_error then
				set_last_error_from_fallible (db_connection)
			else
				set_last_success_message ("Entity with ID " + a_primary_key.out + " deleted from DB successfully")
			end
		end

	wipe_last_items
		do
			last_column_names.wipe_out
			items.wipe_out
		ensure
			items.is_empty
		end

	set_last_error_from_fallible (o: FALLIBLE)
		local
			l_void: like item
		do
			Precursor (o)
			wipe_last_items
			item := l_void
		ensure then
			items.is_empty
			item = Void
		end

	set_last_error (an_error: attached like last_error)
		local
			l_void: like item
		do
			Precursor (an_error)
			wipe_last_items
			item := l_void
		ensure then
			items.is_empty
			item = Void
		end

feature {NONE} -- SQL

	select_all_query: STRING
		do
			Result := "SELECT * FROM " + item_prototype.table_name + " ORDER BY " + item_prototype.Primary_key_db_column_name + " ASC"
			logger.write_debug ("get_select_all_query:" + Result)
		end

	select_query_from_primary_key_query (primary_key_v: like item.primary_key): STRING
		do
			Result := "SELECT * FROM " + item_prototype.table_name + " WHERE " + item_prototype.Primary_key_db_column_name + "=" + primary_key_v.out
			logger.write_debug ("get_select_query_from_primary_key_query:" + Result)
		end

	delete_query_from_primary_key_query (primary_key_v: like item.primary_key): STRING
		do
			Result := "DELETE FROM " + item_prototype.table_name + " WHERE " + item_prototype.Primary_key_db_column_name + "=" + primary_key_v.out + ";"
			logger.write_debug ("delete_query_from_primary_key_query:" + Result)
		end

	insert_query: STRING
			-- Based on fields_mapping redifine it for the fields you want to insert
			-- and on item's values
		require
			non_void_item: attached item
			valid_item: attached item as l_item and then l_item.valid_for_insert
		local
			l_fields_mapping: like item_prototype.fields_mapping
			l_key: STRING
			l_value: ANY
			l_keys, l_values, l_val_to_append: STRING
		do
			l_keys := ""
			l_values := ""
			Result := ""
			if attached item as l_item then
				Result.append ("INSERT INTO " + l_item.table_name)
				across
					l_item.fields_mapping as l_field
				loop
					l_key := l_field.item.db_field_name
					l_value := l_field.item.value_to_set
					l_keys.append (l_key)
					if attached {INTEGER_64} l_value as l_int then
						if l_int <= 0 and l_key.is_equal (l_item.primary_key_db_column_name) then
							l_val_to_append := "DEFAULT"
						else
							l_val_to_append := l_int.out
						end
					elseif attached {STRING_8} l_value as l_value_s then
						l_val_to_append := "'" + l_value_s + "'" -- TODO: escape characters like '"' here!
					else
						logger.write_debug("Adding value:" + l_value.out + " to key:" + l_key + " as not recognized_type")
						l_val_to_append := l_value.out
					end
					l_values.append (l_val_to_append)
					if not l_field.is_last then
						l_values.append (",")
						l_keys.append (",")
					end
				end
				Result.append ("(" + l_keys + ")")
				Result.append (" VALUES ")
				Result.append ("(" + l_values + ")")
				Result.append (";")
				logger.write_debug ("insert_query:" + Result)
			else
				set_last_error(create {ATTACHED_OBJECT_EXPECTED}.make ("Trying to get insert query of a void item..."))
			end
		end

	update_query: STRING
			-- Based on fields_mapping redifine it for the fields you want to insert
			-- and on item's values
		require
			non_void_item: attached item
			valid_item: attached item as l_item and then l_item.valid_for_update
		local
			l_key: like {DB_FIELD[ANY]}.db_field_name
			l_value: ANY
			l_treated_key, l_treated_value: STRING
			l_add_field_to_set: BOOLEAN
		do
			Result := ""
			if attached item as l_item then
				Result.append ("UPDATE " + l_item.table_name + " SET ")
				across
					l_item.fields_mapping as l_db_field
				loop
					l_key := l_db_field.item.db_field_name
					l_value := l_db_field.item.value_to_set
					l_treated_key := l_key
					l_add_field_to_set := True
					l_treated_value := ""
					if attached {INTEGER_64} l_value as l_int then
						if l_key.is_equal (l_item.primary_key_db_column_name) then
							l_add_field_to_set := False -- field is primary_key dont add it for update statement
						else
							l_treated_value := l_int.out
						end
					elseif attached {STRING_8} l_value as l_value_s then
						l_treated_value := "'" + l_value_s + "'" -- TODO: escape characters like '"' here!
					else
						logger.write_warning("Adding value:" + l_value.out + " to key:" + l_key + " as not recognized_type")
						l_treated_value := l_value.out
					end
					if l_add_field_to_set then
						Result.append (l_treated_key)
						Result.append (" = ")
						Result.append (l_treated_value)
						if not l_db_field.is_last then
							Result.append (",")
						end
					end
				end
				Result.append (" WHERE " + l_item.Primary_key_db_column_name + "=" + l_item.primary_key.out + ";")
				logger.write_debug ("update_query :" + Result + "-")
			else
				set_last_error(create {ATTACHED_OBJECT_EXPECTED}.make ("Trying to get insert query of a void item..."))
			end
		end

feature {NONE} -- Implementation

	start
			-- This method is used by the class DB_SELECTION, and is executed after the first
			-- iteration step of 'load_result', it provides some facilities to control, manage, and/or
			-- display data resulting of a query.
			-- In this example, it simply prompts column name on standard output.
		require else
			valid_db_connection: db_connection.valid_resultset
			attached last_column_names
		local
			i: INTEGER
			tuple: DB_TUPLE
		do
			wipe_last_items
			if db_connection.valid_resultset and attached db_connection.cursor as l_cursor then
				create tuple.copy (l_cursor)
				from
					i := 1
				until
					i > tuple.count
				loop
					if attached tuple.column_name (i) as s then
						last_column_names.extend (s)
						logger.write_debug ("DB Query Column " + i.out + ":" + s)
					end
					i := i + 1
				end
			else
				set_last_error (create {ATTACHED_OBJECT_EXPECTED}.make("Unable to get database cursor"))
			end
		end

	execute
			-- This method is also  used by the class DB_SELECTION, and is executed after each
			-- iteration step of 'load_result', it provides some facilities to control, manage, and/or
			-- display data resulting of a query.
			-- Note: only executed if not has_error
			--
			-- In this example, it simply prompts column name on standard output.
			-- Prompt column values on standard output.
		local
			l_item: like item
		do
			if not has_error then
				create l_item.make_from_db_service (Current)
				if attached l_item.last_error then
					logger.write_error ("execute error during execute of DB_Service")
					last_error := l_item.last_error
				else
					items.put (l_item, l_item.primary_key)
				end
			end
		end

feature {NONE} -- Implementation

	create_or_update_entity_impl (a_json_string: STRING)
		require
			attached_item: attached item as l_i
			valid_item: l_i.valid_for_insert or l_i.valid_for_update
		local
			l_qry: like insert_query
			l_is_insert: BOOLEAN
			l_msg: STRING
		do
			if attached item as l_item then
				l_is_insert := l_item.valid_for_insert
				if l_is_insert then
					l_qry := insert_query
				else
					l_qry := update_query
				end
				db_connection.execute_update (l_qry)
				if db_connection.has_error then
					l_msg := "last DB modification did not work with json:" + a_json_string
					if attached db_connection.last_error as l_err then
						l_msg.append ("-error:" + l_err.out)
					end
					set_last_error( create {INSERT_ERROR}.make (l_msg) )
					db_connection.wipe_last_error
				else
					if l_is_insert then
						set_last_success_message ("Entity created into DB successfully")
					else
						set_last_success_message ("Entity updated into DB successfully")
					end
				end
			else
				check
					should_not_happen: False
				end
			end
		end


invariant
	valid_item: attached item implies last_error = Void
	valid_items: items.count > 0 implies last_error = Void
	valid_last_error_items_item: attached last_error implies item = Void and items.count = 0

end -- class
