note
	description: "Summary description for {JSON_UTIL}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	JSON_UTIL

inherit
	LOGGABLE

feature --

	last_error: detachable SIT_ERROR


	adapted_for_parser ( s : STRING ): STRING
		do
			Result := s.twin
			if not s.item (1).is_equal ('[') then
				Result.prepend("[")
				Result.append ("]")
			end
		end


	item_from_json_array(a_json_array: JSON_ARRAY; l_field_name: STRING): detachable ANY
		do
			logger.write_debug ("Debug Output:" + a_json_array.debug_output)
			across
				a_json_array as l_json_array_item
			loop
				if attached {JSON_STRING} l_json_array_item as l_json_array_s then
					Result := l_json_array_s
				else
					create {PARSE_ERROR} last_error.make ("l_json_array_item is of unknown Type:" + l_json_array_item.item.representation)
				end
			end
		end

end
