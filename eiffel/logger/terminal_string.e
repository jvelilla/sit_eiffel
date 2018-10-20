note
	description: "Summary description for {TERMINAL_STRING}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	TERMINAL_STRING

inherit
	STRING
		redefine
			out
		end

create
	make,
	make_from_string

feature -- Intialize


feature -- Status report

	foreground_color: INTEGER
		attribute
			Result := Foreground_black
		end

	modifier: INTEGER -- Default 0 is no modifier

	valid_modifier (a_modifier: like modifier): BOOLEAN
		local
			l_modifiers: ARRAY[like modifier]
		do
			l_modifiers := <<Modifier_bold, Modifier_underline>>
			Result := l_modifiers.has (a_modifier)
		end

	valid_foreground_color (a_fg_color: like foreground_color): BOOLEAN
		local
			l_fg_colors: ARRAY[like foreground_color]
		do
			l_fg_colors := <<Foreground_black, Foreground_red, Foreground_green, Foreground_blue>>
			Result := l_fg_colors.has (a_fg_color)
		end

feature -- Status setting

	set_foreground_color (a_fg_color: like foreground_color)
		require
			valid_foreground_color (a_fg_color)
		do
			foreground_color := a_fg_color
		end

	set_modifier (a_modifier: like modifier)
		require
			valid_modifier (a_modifier)
		do
			modifier := a_modifier
		end




feature -- Special Characters

	Escape_sequence: STRING = "%/27/"
	Reset_sequence: STRING = "[0m"

feature -- Foreground Colors

	Foreground_black: INTEGER = 30
	Foreground_red: INTEGER = 31
	Foreground_green: INTEGER = 32
	Foreground_blue: INTEGER = 34

feature -- Background Colors

	Background_white: INTEGER = 15

	Modifier_bold: INTEGER = 1
	Modifier_underline: INTEGER = 4


feature -- Output

	out: STRING
		local
			l_to_prepend: STRING --more humain readable
		do
			create l_to_prepend.make_from_string (Escape_sequence)
			l_to_prepend.append ("[")
			if modifier /= 0 then
				l_to_prepend.append (";")
				l_to_prepend.append (modifier.out)
			end
			l_to_prepend.append (foreground_color.out)
			l_to_prepend.append ("m")

			Result := Precursor
			Result.prepend (l_to_prepend)
			-- Reset
			Result.append (Escape_sequence)
			Result.append (Reset_sequence)
		end

end
