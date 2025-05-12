local tz = nil

local function turn_on(brightness)
	client:publish{ topic="zigbee2mqtt/bulb_bedroom_01/set", payload=json.encode{state ="ON", brightness = brightness}}
end

local function turn_off()
	client:publish{ topic="zigbee2mqtt/bulb_bedroom_01/set", payload=json.encode{state = "OFF"}}
end

local function timer_ran_out()
	turn_off()
	log('switch_bedroom', 'turning light off (timer ran out)')
end

local BRIGHTNESS_DIM, BRIGHTNESS_FULL = 2, 254

return {
	topic = "zigbee2mqtt/switch_bedroom",
	pattern = "zigbee2mqtt/switch_bedroom",
	on_init = function()
		tz = require('tz')
	end,
	on_match = function(payload)
		local action = json.decode(payload).action
		if action == 'on' then -- short press
			local brightness = BRIGHTNESS_FULL

			local hour = tz.date('*t', os.time(), 'Europe/Budapest').hour

			if hour >= 23 or hour < 06 then
				brightness = BRIGHTNESS_DIM
				log('switch_bedroom', "it's dim")
			end

			turn_on(brightness)

			log('switch_bedroom', 'turning light on (timed)')

			events.add('bedroom_timer', 60*60*4, nil, timer_ran_out)
		elseif action == 'brightness_move_up' then -- long press
			turn_on(BRIGHTNESS_FULL)

			log('switch_bedroom', 'turning light on (bright)')
		elseif action == 'off' then -- short press
			turn_off()
			log('switch_bedroom', 'turning light off (manual)')

			events.remove('bedroom_timer')
		end
	end
}
