note
	description: "Summary description for {COMPANY}."
	author: "Philippe Gachoud"
	date: "$Date$"
	revision: "$Revision$"

class
	COMPANY

inherit
	PARENT_DB_ENTITY
		rename
			primary_key as id,
			set_primary_key as set_id,
			Primary_key_db_column_name as Id_db_column_name
		redefine
			default_create,
			fields_mapping,
			table_name,
			out
		end

create
	default_create,
	make_from_json,
	make_from_db_service

feature {NONE} -- Initialization

	default_create
		do
			Precursor
			name := ""
			main_email := ""
			main_phone := ""
		end


feature -- DB Field names

	Name_db_column_name: STRING = "name"

	Main_email_db_column_name: STRING = "main_email"

	Main_phone_db_column_name: STRING = "main_phone"

	fields_mapping: LINKED_LIST[DB_FIELD[ANY]]
		do
			Result := Precursor
			Result.extend (create {DB_FIELD[like name]}.make (Name_db_column_name, agent set_name (?), name))
			Result.extend (create {DB_FIELD[like main_email]}.make (Main_email_db_column_name, agent set_main_email (?), main_email))
			Result.extend (create {DB_FIELD[like main_phone]}.make (Main_phone_db_column_name, agent set_main_phone (?), main_phone))
		end

feature -- Access

	table_name: STRING
		once
			Result := generating_type.out
			Result.to_lower
		end

	name: STRING

	main_email: STRING

	main_phone: STRING

feature -- Status setting


	set_name (v: STRING)
		do
			name := v
		ensure
			name = v
		end

	set_main_email (v: STRING)
		do
			main_email := v
		ensure
			main_email = v
		end

	set_main_phone (v: STRING)
		do
			main_phone := v
		ensure
			main_phone = v
		end


feature -- Status report

	out: STRING
		do
			Result := "id:" + id.out + "-"
			Result.append ("name:" + name + "-")
			Result.append ("main_email:" + main_email + "-")
			Result.append ("main_phone:" + main_phone + "-")
		end

feature -- JSON


feature -- Cursor movement

feature -- Element change

feature -- Removal

feature -- Resizing

feature -- Transformation

feature -- Conversion

feature -- Duplication

feature -- Miscellaneous

feature -- Basic operations

feature -- Obsolete

feature -- Inapplicable

feature {NONE} -- Implementation

invariant
	main_email_length_as_expected: main_email.count >= 0 and main_email.count <= 50
	main_email_length_as_expected: main_phone.count >= 0 and main_phone.count <= 50

end
