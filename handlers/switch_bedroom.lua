local tz = nil

local log_tag = 'switch_bedroom'

local bulb1 = "zigbee2mqtt/bedroom/light/bulb1/set"
local bulb2 = "zigbee2mqtt/bedroom/light/bulb2/set"

local main_timer = 'bedroom_timer'

local function gethour()
	return tz.date('*t', os.time(), 'Europe/Budapest').hour
end

local function turn_on_daytime()
	local hour = gethour()

	local color = hour > 18 and "warm" or "neutral"

	local p1 = json.encode{ color_temp = color, transition = 0.2 }
	local p2 = json.encode{ brightness = 255, transition = 2 }

	client:publish{ topic = bulb1, payload = p1 }
	client:publish{ topic = bulb2, payload = p1 }

	routines.sleep(0.3)

	client:publish{ topic = bulb1, payload = p2 }
	client:publish{ topic = bulb2, payload = p2 }
end

local function turn_on_nighttime()
	client:publish{ topic = bulb1, payload = json.encode{ brightness = 10, transition = 2 } }
	client:publish{ topic = bulb2, payload = json.encode{ brightness =  0, transition = 2 } }
	log(log_tag, 'turning down brightness')

	routines.sleep(3)

	client:publish{ topic = bulb1, payload = json.encode{ color = {rgb = "255,165,0"}, transition = 3 } }
	log(log_tag, 'adjusting light temperature (nighttime)')
end

local function turn_off()
	local p1 = json.encode{ brightness = 0, transition = 2 }
	local p2 = json.encode{ brightness = 0 }

	client:publish{ topic = bulb1, payload = p1 }
	client:publish{ topic = bulb2, payload = p1 }

	routines.sleep(2.2)

	client:publish{ topic = bulb1, payload = p2 }
	client:publish{ topic = bulb2, payload = p2 }

	routines.sleep(0.2)

	client:publish{ topic = bulb1, payload = p2 }
	client:publish{ topic = bulb2, payload = p2 }
end

local function timer_ran_out()
	turn_off()
	log(log_tag, 'turning lights off (timer ran out)')
end

return {
	topic = "zigbee2mqtt/bedroom/switch/+",
	pattern = "zigbee2mqtt/bedroom/switch/(.+)",
	on_init = function()
		tz = require('tz')
	end,
	on_match = function(payload, switch_name)
		local action = json.decode(payload).action
		if action == 'on' then -- short press
			local hour = gethour()

			log(log_tag, 'turning lights on (timed)', switch_name)

			if hour >= 22 or hour < 06 then
				log(log_tag, "it's late")
				routines.register(turn_on_nighttime)
			else
				routines.register(turn_on_daytime)
			end

			events.add(main_timer, 60*60*4, nil, timer_ran_out)

		elseif action == 'brightness_move_up' then -- long press
			log(log_tag, 'turning lights on (bright)', switch_name)

			routines.register(turn_on_daytime)

		elseif action == 'off' then -- short press
			log(log_tag, 'turning lights off (manual)', switch_name)
			routines.register(turn_off)

			events.remove(main_timer)
		end
	end
}
