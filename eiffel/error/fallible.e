note
	description: "Capable of making mistakes or being wrong"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	FALLIBLE

inherit
	LOGGABLE


feature -- Status report

	last_error: detachable SIT_ERROR
		-- Last error

	last_success_message: detachable STRING
		-- If any

	has_error: BOOLEAN
			-- Based on last_error
		do
			Result := last_error /= Void
		end

feature -- Status setting

	set_last_error_from_fallible (o: FALLIBLE)
		require
			attached o.last_error
		do
			last_error := o.last_error
			last_success_message := Void
		ensure
			attached o.last_error implies last_success_message = Void
		end

	set_last_error (an_error: attached like last_error)
		do
			last_error:= an_error
			last_success_message := Void
		ensure
			attached an_error implies last_success_message = Void
		end

	set_last_success_message_from_fallible (o: attached like Current)
		require
			attached o.last_success_message
		do
			last_success_message := o.last_success_message
			last_error := Void
		ensure
			attached o.last_success_message implies last_error = Void
		end

	set_last_success_message (a_msg: attached like last_success_message)
		do
			last_success_message := a_msg
			last_error := Void
		ensure
			attached a_msg implies last_error = Void
		end

	wipe_last_error
			-- Once you consider having treated it
		do
			last_error := Void
		ensure
			last_error = Void
		end

	wipe_last_success_message
		do
			last_success_message := Void
		ensure
			last_success_message = Void
		end

invariant
	never_both_attached: {SIT_UTIL}.never_both (attached last_error, attached last_success_message)

end
