note
	description: "Summary description for {SIT_UTIL}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIT_UTIL

create
	default_create

feature -- could be in class BOOLEAN

	double_implies, reversible_implies, never_both (a, b: BOOLEAN): BOOLEAN
			-- Into boolean class with never_with
	    do
	        Result := not (a and b)
		ensure
			instance_free: class
	    end

end
