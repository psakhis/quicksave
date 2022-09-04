-- license:BSD-3-Clause
-- copyright-holders:Jack Li
local exports = {
	name = 'gunlight',
	version = '0.0.4',
	description = 'Gunlight plugin',
	license = 'BSD-3-Clause',
	author = { name = 'Jack Li' } }

local gunlight = exports

function gunlight.startplugin()

	-- List of gunlight buttons, each being a table with keys:
	--   'port' - port name of the button being gunlightd
	--   'mask' - mask of the button field being gunlightd
	--   'type' - input type of the button being gunlightd
	--   'key' - input_seq of the keybinding
	--   'key_cfg' - configuration string for the keybinding
	--   'on_frames' - number of frames button is pressed
	--   'off_frames' - number of frames button is released
	--   'button' - reference to ioport_field
	--   'counter' - position in gunlight cycle
	local buttons = {}

	local menu_handler

	local function process_frame()
		local input = manager.machine.input

		local function process_button(button)
			local pressed = input:seq_pressed(button.key)			
			if pressed then			       
				local state = button.counter < button.on_frames and 1 or 0
				button.counter = (button.counter + 1) % (button.on_frames + button.off_frames)
				return state
			else
				button.counter = 0
				return 0
			end
		end

		-- Resolves conflicts between multiple gunlight keybindings for the same button.
		local button_states = {}
                local scr = nil
                local COLOR_WHITE = 0xffffffff
               		
		for i, button in ipairs(buttons) do
			if button.button then
				local key = button.port .. '\0' .. button.mask .. '.' .. button.type				
				local state = button_states[key] or {0, button.button}
				state[1] = process_button(button) | state[1]				
				button_states[key] = state						
			end
		end
		for i, state in pairs(button_states) do
		        --psakhis light
		        if state[1] == 1 then
			   for i,v in pairs(manager.machine.screens) do 
		                  scr = i			                  		                 	                    	                      		                  
		                  break
		           end			         	                
		           manager.machine.screens[scr]:draw_box(0, 0,  manager.machine.screens[scr].width, manager.machine.screens[scr].height, COLOR_WHITE,COLOR_WHITE)		                     		                   		                             	         		                   		      		                		                  		         
		        end   
		        --end psakhis light
			state[2]:set_value(state[1])						
		end
	end

	local function load_settings()
		local loader = require('gunlight/gunlight_save')
		if loader then
			buttons = loader:load_settings()
		end
	end

	local function save_settings()
		local saver = require('gunlight/gunlight_save')
		if saver then
			saver:save_settings(buttons)
		end

		menu_handler = nil
		buttons = {}
	end

	local function menu_callback(index, event)
		if menu_handler then
			return menu_handler:handle_menu_event(index, event, buttons)
		else
			return false
		end
	end

	local function menu_populate()
		if not menu_handler then
			menu_handler = require('gunlight/gunlight_menu')
			if menu_handler then
				menu_handler:init_menu(buttons)
			end
		end
		if menu_handler then
			return menu_handler:populate_menu(buttons)
		else
			return {{_p('plugin-gunlight', 'Failed to load gunlight menu'), '', 'off'}}
		end
	end

	emu.register_frame_done(process_frame)
	emu.register_prestart(load_settings)
	emu.register_stop(save_settings)
	emu.register_menu(menu_callback, menu_populate, _p('plugin-gunlight', 'GunLight gunlight'))
end

return exports
