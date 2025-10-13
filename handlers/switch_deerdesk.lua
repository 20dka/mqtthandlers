local log_tag = "switch_ozi_ketgombos"

local netio_topic = "devices/netio_deer/messages/devicebound/"

local actions = {
	turn_off = 0,
	turn_on = 1,
	short_off = 2,
	short_on = 3,
	toggle = 4,
	no_change = 5,
	ignore = 6
}


local function set_outputs(outputs)
	client:publish{ topic=netio_topic, payload=json.encode{ Operation = "SetOutputs", Outputs = outputs }}
end

return {
	topic = "zigbee2mqtt/livingroom/switch/ozi_ketgombos",
	pattern = "zigbee2mqtt/livingroom/switch/ozi_ketgombos",
	on_match = function(payload)
		local action = json.decode(payload).action
		if action == 'on' then -- short press
			set_outputs{ {ID = 2, Action = actions.toggle } }

			log(log_tag, 'toggling power for monitor')
		elseif action == 'off' then -- short press
			set_outputs{ {ID = 2, Action = actions.short_off } }

			log(log_tag, 'power cycling monitor')
		elseif action == 'brightness_move_up' then -- long press
			set_outputs{ {ID = 1, Action = actions.toggle } }

			log(log_tag, 'toggling PC power')
		end
	end
}
