note
	description: "Summary description for {EMPTY_RESULTSET}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	EMPTY_RESULTSET

inherit
	DB_ERROR

create
	make

feature -- Status Report

	http_status_code: like {HTTP_STATUS_CODE}.ok
			-- Returns the corresponding HTTP_STATUS_CODE
		do
			Result := {HTTP_STATUS_CODE}.bad_request
		end

end
