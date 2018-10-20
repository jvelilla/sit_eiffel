note
	description: "Summary description for {LOGGABLE}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	LOGGABLE


feature -- Initialize


feature -- Logger

	class_for_logger: like logger.current_class
		do
			Result := generating_type.out
		end

	logger: SIT_LOGGER
		do
			create Result.make_from_class (class_for_logger)
		end

end
