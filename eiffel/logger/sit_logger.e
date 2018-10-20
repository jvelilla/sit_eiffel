note
	description: "G is the current class of object to be logged"
	colors_links: "Inspired from https://stackoverflow.com/questions/2616906/how-do-i-output-coloured-text-to-a-linux-terminal"
	stackoverflow: "https://stackoverflow.com/questions/52859429/eiffel-is-there-a-way-to-print-colorized-characters-into-a-terminal-console/52860686#52860686"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIT_LOGGER

inherit
	LOG_LOGGING_FACILITY
		redefine
			write
		end

create
	make_from_class

feature -- Constants

	Log_file_path: STRING
		once
			Result := "application.log"
		end

feature {NONE} -- Initialization

	make_from_class (a_class: like current_class)
		do
			make
            current_class := a_class
			create app_log_file_name.make_from_string(Log_file_path)
			-- logger.enable_default_system_log
			enable_default_file_log -- by default the log file is "system.log"
			-- Enable DEBUG
			default_log_writer_file.enable_debug_log_level
			enable_default_stderr_log
			default_log_writer_stderr.enable_debug_log_level
			-- Add file appender
          	create app_file_log_writer
            app_file_log_writer.set_path (app_log_file_name)
            register_log_writer (app_file_log_writer)
            if app_file_log_writer.has_errors then
                write_emergency ("Cannot open log file '" + app_log_file_name.utf_8_name + "'%N")
            end
		end

feature -- Initialization

	initialize_terminal: INTEGER
	    external "C inline"
	    alias "[
	        #ifdef EIF_WINDOWS
	            {
	                HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
	                if (hOut == INVALID_HANDLE_VALUE) {
	                	return GetLastError();
	                }
	                DWORD dwMode = 0;
	                if (!GetConsoleMode(hOut, &dwMode)) {
	                	return GetLastError();
	                }
	                dwMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
	                if (!SetConsoleMode(hOut, dwMode)) {
        				return GetLastError();
    				}
    				return 0;
	            }
		#else
		      /* Check for other platforms */
		    return 0;
	        #endif
	    ]"
	end

feature -- Access

	current_class: STRING

	app_log_file_name: PATH

    app_file_log_writer: LOG_WRITER_FILE

    is_colorized, is_terminal_output: BOOLEAN = True

feature {NONE} -- Implementation

	write (a_priority: INTEGER; msg: STRING)
		local
			l_msg: like msg
		do
--			msg.prepend (({like Current}).generating_type.out + ":") --TODO: add client class name here
			l_msg := msg
			l_msg.prepend ("(" + current_class + "):")
			if is_colorized and is_terminal_output then
				l_msg := colorized (a_priority, l_msg).out
			end

--			print (l_msg)
--			print ("%/27/[1;31mTEST%/27/[0m<--RESET%N") -- Bold light Red
--			print ("%/27/[31;15mTEST31.1%/27/[0m<--RESET%N") -- Red on white

			Precursor(a_priority, l_msg)
		end

	colorized (a_priority: INTEGER; a_msg: STRING): TERMINAL_STRING
		local
			l_red_array: ARRAY[like a_priority]
		do
			l_red_array := <<Log_alert, Log_error, Log_critical>>
			create Result.make_from_string (a_msg)
			if l_red_array.has (a_priority) then
				Result.set_foreground_color ({TERMINAL_STRING}.Foreground_red)
			elseif a_priority = Log_debug then
				Result.set_foreground_color ({TERMINAL_STRING}.Foreground_black)
			elseif a_priority = Log_information then
				Result.set_foreground_color ({TERMINAL_STRING}.Foreground_green)
			else
				Result.set_foreground_color ({TERMINAL_STRING}.Foreground_black)
			end
		end

end
