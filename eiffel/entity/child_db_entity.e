note
	description: "Summary description for {CHILD_DB_ENTITY}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CHILD_DB_ENTITY

inherit
	DB_ENTITY

feature -- Status report

	parent: PARENT_DB_ENTITY

feature -- Status setting

	set_parent (a_parent: like parent)
		do
			parent := a_parent
		end

end
