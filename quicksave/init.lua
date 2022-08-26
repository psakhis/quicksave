-- license:BSD-3-Clause
-- copyright-holders:Sergi Clara
local exports = {
	name = 'quicksave',
	version = '0.0.1',
	description = 'Quicksave macro plugin',
	license = 'BSD-3-Clause',
	author = { name = 'Sergi Clara' } }

local commonui

local quicksave = exports
local quicksave_folder = ''
local quicksave_settings = {
	save_input = "",
	load_input = "",
	slot_state = 0,
	snapshot = false,	
	autoload = false
}

function quicksave.set_folder(path)
	quicksave_folder = path
end

function quicksave.startplugin()
        
        local edit_switch_poller                                    
	local json = require('json')

	local function save_settings()
		local file = io.open(quicksave_folder .. '/settings.cfg', 'w')
		if file then
			file:write(json.stringify(quicksave_settings, {indent = true}))
		end
		file:close()
	end

	local function load_settings()	      
		local file = io.open(quicksave_folder .. '/settings.cfg', 'r')
		if file then
			local settings = json.parse(file:read('a'))
			if settings then
				quicksave_settings = settings				
			end
			file:close()
		end
	end
	
	local function save()        
               local scr = nil
               manager.machine:save(quicksave_settings.slot_state)
	       if quicksave_settings.snapshot then			        
		   for i,v in pairs(manager.machine.screens) do 
		      scr = i		         	         
		      break
		   end		   
		   local snap_file = emu.romname() .. "/" .. quicksave_settings.slot_state .. ".png"  		        		      		       
		   manager.machine.screens[scr]:snapshot(snap_file)
	       end		
        end
        
	local function auto_load()	      		
		if quicksave_settings.autoload then			
			manager.machine:load(quicksave_settings.slot_state)							
		end
	end
		
	local function menu_populate()
		local menu = {}
									      
	        local quicksave_input = _p('plugin-quicksave', quicksave_settings.save_input)
		menu[1] =  { _p('plugin-quicksave', 'Save Input'), quicksave_input,  edit_switch_poller and 'lr' or ''}
	
		local quickload_input = _p('plugin-quicksave', quicksave_settings.load_input)
		menu[2] =  { _p('plugin-quicksave', 'Load Input'), quickload_input,  edit_switch_poller and 'lr' or '' }
	        
	        local slot_state = quicksave_settings.slot_state
	        menu[3] =  { _p('plugin-quicksave', 'State Slot'), slot_state, (slot_state > 0) and 'lr' or 'r' }
	        
	        local snapshot = quicksave_settings.snapshot
	        if snapshot then	         
	        	menu[4] =  { _p('plugin-quicksave', 'Save Snapshot'), "Yes", 'l' }
	        else
	        	menu[4] =  { _p('plugin-quicksave', 'Save Snapshot'), "No", 'r' }
		end
		
		local autoload = quicksave_settings.autoload
	        if autoload then	         
	        	menu[5] =  { _p('plugin-quicksave', 'Auto Load'), "Yes", 'l' }
	        else
	        	menu[5] =  { _p('plugin-quicksave', 'Auto Load'), "No", 'r' }
		end		
	
		
		return menu
	end
	
	local function menu_callback(index, event)
	
		if event == "cancel" or ((index == 1 or index == 2) and (event == "left" or event == "right" or event == "down" or event == "up")) then 
			edit_switch_poller = nil 
			return false 		 
		end
					
		if edit_switch_poller then		       
			if edit_switch_poller:poll() then			       
				if edit_switch_poller.sequence and index == 1 then					  				       				
					quicksave_settings.save_input = manager.machine.input:seq_to_tokens(edit_switch_poller.sequence)					
				end
				if edit_switch_poller.sequence and index == 2 then					  				       				
					quicksave_settings.load_input = manager.machine.input:seq_to_tokens(edit_switch_poller.sequence)					
				end
				edit_switch_poller = nil
				return true
			end
			return false
		end			
		
		-- Quicksave/Quickload inputs
		if index == 1 or index == 2 then
			if event == 'select' then
				if not commonui then
					commonui = require('commonui')
				end				
				edit_switch_poller = commonui.switch_polling_helper()
				return true
			end
                end
                
                --Slot
                if index == 3 then
			if event == "left" then 
		    		quicksave_settings.slot_state = quicksave_settings.slot_state - 1
		    	end	
		    	if event == "right" then 
		    		quicksave_settings.slot_state = quicksave_settings.slot_state + 1
		    	end	
		    	return true
		end
		
		--Snapshoot
                if index == 4 then
			if event == "left" then 
		    		quicksave_settings.snapshot = false
		    	end	
		    	if event == "right" then 
		    		quicksave_settings.snapshot = true
		    	end	
		    	return true
		end

		--Autoload
                if index == 5 then
			if event == "left" then 
		    		quicksave_settings.autoload = false
		    	end	
		    	if event == "right" then 
		    		quicksave_settings.autoload = true
		    	end	
		    	return true
		end		
                
		return false
	end
               	
	local function process_quick()
					 
		local inp = manager.machine.input
										 		 		
		if inp:seq_pressed(inp:seq_from_tokens(quicksave_settings.save_input)) then			   		 	  			   
		    save() 
		end
		
		if inp:seq_pressed(inp:seq_from_tokens(quicksave_settings.load_input)) then			   	  			   
		   manager.machine:load(quicksave_settings.slot_state)		 
		end
				
        end
        
	emu.register_periodic(process_quick)
	emu.register_prestart(load_settings)	
	emu.register_start(auto_load)
	emu.register_stop(save_settings)		
	
	emu.register_menu(menu_callback, menu_populate, _p('plugin-quicksave', 'QuickSave'))
end

return exports
