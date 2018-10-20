note
	description: "Summary description for {PARSE_ERROR}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	PARSE_ERROR

inherit
	SIT_ERROR

create
	make

feature -- Status Report

	http_status_code: like {HTTP_STATUS_CODE}.ok
			-- Returns the corresponding HTTP_STATUS_CODE
		do
			Result := {HTTP_STATUS_CODE}.internal_server_error
		end
end
