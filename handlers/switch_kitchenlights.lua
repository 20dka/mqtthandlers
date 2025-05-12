local tz = nil

local function turn_on(brightness)
	client:publish{ topic="wled/kitchen", payload=(brightness and tostring(brightness) or "ON") }
end

local function turn_off()
	client:publish{ topic="wled/kitchen", payload="OFF" }
end

local function timer_ran_out()
	turn_off()
	log('switch_kitchen', 'turning light off (timer ran out)')
end

return {
	topic = "zigbee2mqtt/negygombos",
	pattern = "zigbee2mqtt/negygombos",
	on_init = function()
		tz = require('tz')
	end,
	on_match = function(payload)
		local action = json.decode(payload).action
		if action == 'on' then -- short press
			turn_on(brightness)

			log('switch_kitchen', 'turning light on (timed)')

			events.add('bedroom_timer', 60*60*4, nil, timer_ran_out)
		elseif action == 'off' then -- short press
			turn_off()
			log('switch_kitchen', 'turning light off (manual)')

			events.remove('bedroom_timer')
		end
	end
}
