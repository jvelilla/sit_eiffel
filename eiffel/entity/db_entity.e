note
	description: "Summary description for {DB_ENTITY}."
	author: "Philippe Gachoud"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	DB_ENTITY

inherit
	LOGGABLE
		redefine
			default_create
		end

	FALLIBLE
		redefine
			default_create
		end

	ENTITY
		redefine
			default_create
		end

feature {NONE} -- Initialize

	default_create
		do
			Precursor {ENTITY}
			Precursor {LOGGABLE}
			Precursor {FALLIBLE}
		ensure then
			not has_error
			not exists_in_db
		end

	make_from_db_service (a_db_service: DB_SERVICE[like Current])
		do
			default_create
			set_from_db_service (a_db_service)
		ensure
			valid_last_error: primary_key <= 0 implies attached last_error
		end

	make_from_json (a_json_string: STRING)
		do
			default_create
			set_from_json (a_json_string)
		end

feature -- Status Report

	exists_in_db: BOOLEAN
		-- Is Current object linked to DB

	valid_for_insert: BOOLEAN
		-- Is Current object valid to be inserted into DB
		-- Redefine me if you need more business
		do
			Result := primary_key = 0
		end

	valid_for_update: BOOLEAN
		-- Is Current object valid to be inserted into DB
		-- Redefine me if you need more business
		do
			Result := primary_key > 0
		end

feature -- DB Fields

	primary_key: INTEGER_64 -- most of the time it's the id field

feature -- DB Field names

	Primary_key_db_column_name: STRING = "id"

	fields_mapping: LINKED_LIST[DB_FIELD[ANY]]
			-- Fields mappings for queries
			-- value is eiffel_field_name (id,name,...), key is database_field_name('id', 'main_name')
		do
			create Result.make
			Result.extend (create {DB_FIELD[like primary_key]}.make (Primary_key_db_column_name, agent set_primary_key (?), primary_key))
		end

feature -- Database

	table_name: STRING
		once
			Result := Current.generating_type.out
			Result.to_lower
		end

feature -- Status setting

	set_primary_key (v: like primary_key)
		do
			primary_key := v
		ensure
			primary_key = v
		end

	set_from_db_service (a_db_service: DB_SERVICE[Like Current])
			-- Calls all setters from a_db_service resultset
		require else
			attached a_db_service.last_column_names
				and then attached a_db_service.cursor
		local
			i: INTEGER
			l_tuple: DB_TUPLE
			l_column_name: STRING
			l_value: detachable ANY
		do
			if attached a_db_service.last_column_names as l_column_names then
				create l_tuple.copy(a_db_service.cursor)
				if l_tuple.count = 0 then
					create {ENTITY_NOT_FOUND} last_error.make("Given resultset is empty")
				else
					from
						i := 1
					until
						i > l_tuple.count
					loop
						l_column_name := l_column_names.at(i)
						l_value := l_tuple.item (i)
						call_setter (l_column_name, l_value)
						i := i + 1
					end
					logger.write_debug (out)
				end
			else
				create {ENTITY_NOT_FOUND} last_error.make("Column names are empty")
			end
		ensure
			valid_last_error: not valid_primary_key (primary_key) implies attached last_error
		end


feature -- Validation

	valid_primary_key (a_primary_key: like primary_key): BOOLEAN
		do
			Result := a_primary_key >= 0
		end

feature -- JSON Form

	to_json_string: STRING
		do
			Result := to_json.representation
		end

	to_json: JSON_OBJECT
			-- Just call the representation to get it as STRING
			-- TODO: refactor with https://www.youtube.com/watch?v=G9AiHaYdqzU&t=24s&list=WL&index=3
		local
			l_int64: INTEGER_64
			is_int: BOOLEAN
			l_field_name: like {DB_FIELD[ANY]}.db_field_name
			l_field_value: like {DB_FIELD[ANY]}.value_to_set
		do
			create Result.make
			across
				fields_mapping as l_field
			loop
				l_field_name := l_field.item.db_field_name
				check
					valid_key_for_json: l_field_name.count > 0
				end
				l_field_value := l_field.item.value_to_set
				if attached {INTEGER_REF} l_field_value as l_int then
--					logger.write_debug("l_field_name:" + l_field_name + "-l_int:" + l_int.out)
					Result.put_integer (l_int.to_integer_64, l_field_name)
				elseif attached {INTEGER_64} l_field_value as l_int then
--					logger.write_debug("l_field_name:" + l_field_name + "-l_int:" + l_int.out)
					Result.put_integer (l_int, l_field_name)
				elseif attached {TUPLE} l_field_value as l_tuple and then attached {INTEGER_64} l_tuple.item (1) as l_int then
--					logger.write_debug("l_field_name:" + l_field_name + "-l_int:" + l_int.out)
					Result.put_integer (l_int, l_field_name)
				elseif attached {STRING} l_field_value as l_s then
--					logger.write_debug("l_field_name:" + l_field_name + "-l_s:" + l_s.out)
					Result.put_string (l_s, l_field_name)
				else
					logger.write_error ("to_json-> Type not found in matching:" + l_field_value.out)
					check
						not_found_item_type: False
					end
				end
			end
		end


	set_from_json (a_json_s: STRING)
		local
--			l_json_serialization: JSON_SERIALIZATION -- AUTOMATIC
			l_json_parser: JSON_PARSER
			l_setter_procedure: PROCEDURE[TUPLE]
			l_field_name: STRING
			l_json_util: JSON_UTIL
			l_any: ANY
		do
			create l_json_util
			logger.write_debug ("set_from_json->Received object:" + a_json_s + "-")
			create l_json_parser.make_with_string (a_json_s)
			l_json_parser.parse_content
			if l_json_parser.is_valid
					and then attached l_json_parser.parsed_json_value as l_parsed_json_value then
				across
					fields_mapping as l_field
				loop
					l_setter_procedure := l_field.item.setter
					l_field_name := l_field.item.db_field_name
					if attached {JSON_OBJECT} l_parsed_json_value as l_json_object then
						if attached {JSON_STRING} l_json_object.item (l_field_name) as l_field_value_s then
							logger.write_debug ("Calling setter of " + l_field_name + " value:" + l_field_value_s.unescaped_string_8)
							l_setter_procedure.call (l_field_value_s.unescaped_string_8) -- Agent call
						elseif attached {JSON_NUMBER} l_json_object.item (l_field_name) as l_field_value_num then
							logger.write_debug ("Calling setter of " + l_field_name + " value:" + l_field_value_num.out)
							l_setter_procedure.call (l_field_value_num.integer_64_item) -- Agent call
						elseif l_field_name.is_equal (primary_key_db_column_name) then
							if attached l_json_object.item (l_field_name) as l_type then
								logger.write_warning ("Treated field is primary key, fieldname:" + l_field_name + " type:" + l_type.generating_type.out + " and has not been found into received object")
							else
								logger.write_warning ("Treated field is primary key, fieldname:" + l_field_name + " type unknown and has not been found into received object")
							end
						else
							create {PARSE_ERROR} last_error.make ("Parsed Json Object is none of the treated ones or field " + l_field_name + " has not been found:" + l_json_object.representation)
						end
					else
						check
							not_reaching_here: False
						end
						create {PARSE_ERROR} last_error.make ("Parsed Json Object is not a JSON_OBJECT:" + l_parsed_json_value.representation)
					end
				end
			else
				create {PARSE_ERROR} last_error.make ("Error parsing Json object from string, parser is not valid:%N" + a_json_s + "%NError:" + l_json_parser.errors_as_string)
			end


			-- AUTOMATIC NOT WORKIG
--			l_json_serialization.register_default (create {JSON_REFLECTOR_SERIALIZATION})
--			if attached {like Current} l_json_serialization.from_json_string (a_json, {detachable like Current}) as l_item then
--				Current.deep_copy (l_item)
--			else
--				create {PARSE_ERROR} last_error.make ("Error parsing Json object from string:" + a_json)
--			end
-- TODO continue here with https://github.com/eiffelhub/json/blob/master/examples/serialization/demo_custom_serialization.e
-- TODO deferred into parent class

--			create l_parser.make_with_string (a_json)
--			if attached l_parser. as jv and l_parser.is_valid then
--				if attached {like Current} json.object (jv, "COMPANY") as res then
--					logger.write_debug(res.out)--TODO continue here
--				end
--			end
		end

feature {NONE} -- Implementation		


	call_setter (a_field_name: like {DB_FIELD[ANY]}.db_field_name; a_value: detachable ANY)
		local
			l_found: BOOLEAN
			l_setter: like {DB_FIELD[ANY]}.setter
		do
			if attached a_value as l_value then
				across
					fields_mapping as l_db_field
				until
					l_found
				loop
					l_found := l_db_field.item.db_field_name.is_equal (a_field_name)
					if l_found then
						l_setter := l_db_field.item.setter
--						logger.write_debug ("l_setter:" + l_setter.out)
--						logger.write_debug ("l_value:" + l_value.out)
						if attached {INTEGER_32_REF} l_value as l_int then
							l_setter.call ([l_int.to_integer_64])
						elseif attached {STRING_8} l_value as l_s then
							l_setter.call ([l_s])
						else
							check
								should_not_happend_otherwise_will_crash: False
								-- If happening check received TYPE and treat it as above
							end
							l_setter.call ([l_value])
						end
					end
				end
				check
					found_field_name: l_found
				end
			else
				set_last_error (create {ATTACHED_OBJECT_EXPECTED}.make("Value for field " + a_field_name + " seems unattached"))
			end
		end

invariant
	valid_primary: valid_primary_key (primary_key)
	not_both_valid: not (valid_for_insert and valid_for_update)

end
