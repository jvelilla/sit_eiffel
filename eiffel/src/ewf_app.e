note
	description: "[
				application service
			]"
	date: "$Date: 2016-10-21 10:45:18 -0700 (Fri, 21 Oct 2016) $"
	revision: "$Revision: 99331 $"

class
	EWF_APP


inherit
	WSF_LAUNCHABLE_SERVICE
		redefine
			initialize
		end

	APPLICATION_LAUNCHER [EWF_APP_EXECUTION]

	LOGGABLE


create
	make_and_launch

feature {NONE} -- Initialization

	initialize
			-- Initialize current service.
		do
			Precursor
			set_service_option ("port", 9999)
			set_service_option ("verbose", "yes")
			logger.write_debug (" -------------------> EWF_APP Application initialize <------------------------")
		end

end
