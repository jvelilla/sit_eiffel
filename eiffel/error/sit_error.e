note
	description: "Summary description for {SIT_ERROR}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIT_ERROR

inherit
	LOGGABLE
		redefine
			out
		end

feature -- Initialization

	make (a_message: like message)
		do
			message := a_message
			logger.write_error("Error created:" + out)
		end

feature -- Access

	message: STRING

	type: STRING
			-- Short message of kind of error
		once
			Result := generating_type.out
		end

feature -- Status report

	out: STRING

		do
			Result := type
			Result.append(":" + message)
		end


feature -- Status Report

	http_status_code: like {HTTP_STATUS_CODE}.ok
			-- Returns the corresponding HTTP_STATUS_CODE
			-- Should be in DB_ERROR maybe... think it!
		deferred
		end


end
