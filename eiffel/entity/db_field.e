note
	description: "G is the type of setter's argument, for set_name(name:STRING_8) it'll be STRING_8"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	DB_FIELD[G]

create
	make

feature -- Initialization

	make (a_field_name: like db_field_name; a_setter: like setter; a_value_to_set: G)
		do
			setter := a_setter
			db_field_name := a_field_name
			value_to_set := a_value_to_set
		end

feature -- Status Report

	setter: PROCEDURE[TUPLE[G]]
		-- The eiffel setter for this field

	db_field_name: STRING

	value_to_set: G

end
