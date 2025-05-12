local tz = nil

local log_tag = 'switch_bedroom'

local bulb1 = "zigbee2mqtt/bedroom/light/bulb1/set"
local bulb2 = "zigbee2mqtt/bedroom/light/bulb2/set"

local main_timer = 'bedroom_timer'
local stage2_timer = 'nighttime_bedroom_stage2'

local function turn_on_daytime()
	events.remove(stage2_timer)

	local p1 = json.encode{ color_temp = "warm" }
	local p2 = json.encode{ brightness = 255, transition = 3 }
	client:publish{ topic = bulb1, payload = p1 }
	client:publish{ topic = bulb2, payload = p1 }

	client:publish{ topic = bulb1, payload = p2 }
	client:publish{ topic = bulb2, payload = p2 }
end

local function turn_on_nighttime()
	client:publish{ topic = bulb1, payload = json.encode{ brightness = 10, transition = 2 } }
	events.add(stage2_timer, 3, nil, function() 
		client:publish{ topic = bulb1, payload = json.encode{ color = {rgb = "255,165,0"}, transition = 3 } }
		log(log_tag, 'adjusting light temperature (nighttime)')
	end)

	client:publish{ topic = bulb2, payload = json.encode{ brightness = 0, transition = 3 } }
	log(log_tag, 'turning down brightness')
end

local function turn_off()
	events.remove(stage2_timer)

	local payload = json.encode{ brightness = 0, transition = 2 }
	client:publish{ topic = bulb1, payload = payload }
	client:publish{ topic = bulb2, payload = payload }
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
			local hour = tz.date('*t', os.time(), 'Europe/Budapest').hour

			log(log_tag, 'turning lights on (timed)', switch_name)

			if hour >= 22 or hour < 06 then
				log(log_tag, "it's late")
				turn_on_nighttime()
			else
				turn_on_daytime()
			end

			events.add(main_timer, 60*60*4, nil, timer_ran_out)

		elseif action == 'brightness_move_up' then -- long press
			log(log_tag, 'turning lights on (bright)', switch_name)

			turn_on_daytime()

		elseif action == 'off' then -- short press
			log(log_tag, 'turning lights off (manual)', switch_name)
			turn_off()

			events.remove(main_timer)
		end
	end
}
