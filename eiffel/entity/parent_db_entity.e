note
	description: "Summary description for {PARENT_DB_ENTITY}. G is the child TYPE"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	PARENT_DB_ENTITY

inherit
	DB_ENTITY
		redefine
			default_create
		end

feature {NONE} -- Initialize

	default_create
		do
			Precursor
			create children.make
		ensure then
			children_created: attached children
		end

feature -- Status report

	children: LINKED_LIST[CHILD_DB_ENTITY]

end
