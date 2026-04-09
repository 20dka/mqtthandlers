local tz = nil

local log_tag = 'switch_bedroom'

local bulb1 = "zigbee2mqtt/bedroom/light/bulb2/set"
local strip = "zigbee2mqtt/bedroom/light/rgb_strip1/set"

-- nappal: izzo maxon

-- ejjel:
-- off, strip gyengen, strip+izzo kozepesen, minden max

-- tart, fel: daytime
-- tart, le: lights out

local stage_id = 1
local stages = { "off", "eepytime", "give me more light", "all out" }

local stage_actions = {}

local main_timer = 'bedroom_timer'

local function gethour()
	return tz.date('*t', os.time(), 'Europe/Budapest').hour
end

local function turn_on_daytime()
	local hour = gethour()

	local color = hour >= 18 and "warm" or "neutral"

	local p1 = json.encode{ color_temp = color, transition = 0.2 }
	local p2 = json.encode{ brightness = 255, transition = 2 }

	client:publish{ topic = bulb1, payload = p1 }

	routines.sleep(0.4)

	client:publish{ topic = bulb1, payload = p2 }

	stage_id = 3

	events.add(main_timer, 60*60*4, nil, timer_ran_out)
end

local function turn_on_all_out(going_up)
	client:publish{ topic = bulb1, payload = json.encode{ brightness = 255, transition = 2 } }
	client:publish{ topic = strip, payload = json.encode{ color_temp = "neutral", transition = 2 } }
	routines.sleep(2.2)
end

local function turn_on_more_light(going_up)
	local p1 = json.encode{ color_temp = "warm" }
	local p2 = json.encode{ brightness = 100, transition = 2 }

	client:publish{ topic = bulb1, payload = p1 }
	routines.sleep(0.2)
	client:publish{ topic = bulb1, payload = p2 }

	if going_up then
		client:publish{ topic = strip, payload = json.encode{ brightness = 255, transition = 2 } }
	else
		client:publish{ topic = strip, payload = json.encode{ color = {rgb = "255,165,0"}, transition = 2 } }
	end
	routines.sleep(2.2)
end

local function turn_on_eepytime(going_up)
	if going_up then
		client:publish{ topic = strip, payload = json.encode{ color = {rgb = "255,165,0"} } }
		routines.sleep(0.1)
	end

	if not going_up then
		client:publish{ topic = bulb1, payload = json.encode{ brightness = 0, transition = 2 } }
	end

	client:publish{ topic = strip, payload = json.encode{ brightness = 50, transition = 2 } }
	routines.sleep(2.2)
end

local function turn_off_nighttime()
	client:publish{ topic = strip, payload = json.encode{ brightness = 0, transition = 2 } }
	routines.sleep(2.2)
end

local function turn_off()
	local p1 = json.encode{ brightness = 0, transition = 2 }
	local p2 = json.encode{ brightness = 0 }

	client:publish{ topic = bulb1, payload = p1 }
	client:publish{ topic = strip, payload = p1 }

	routines.sleep(2.2)

	client:publish{ topic = bulb1, payload = p2 }

	routines.sleep(0.2)

	stage_id = 1

	client:publish{ topic = bulb1, payload = p2 }
end

local function timer_ran_out()
	turn_off()
	log(log_tag, 'turning lights off (timer ran out)')
end

stage_actions = {
	off = turn_off_nighttime,
	eepytime = turn_on_eepytime,
	["give me more light"] = turn_on_more_light,
	["all out"] = turn_on_all_out
}


local function handle_late_statemachine(going_up)
	local new_stage = nil
	if going_up then
		if stage_id < #stages then
			log(log_tag, 'going from stage', stages[stage_id], 'to', stages[stage_id+1])
			stage_id = stage_id+1
			new_stage = stages[stage_id]
		else
			stage_id = #stages
			new_stage = stages[stage_id]
		end
	else
		if stage_id > 1 then
			log(log_tag, 'going from stage', stages[stage_id], 'to', stages[stage_id-1])
			stage_id = stage_id-1
			new_stage = stages[stage_id]
		else
			stage_id = 1
			new_stage = stages[stage_id]
		end
	end

	if new_stage then
		routines.register(stage_actions[new_stage], nil, going_up)
	end
end

return {
	topic = "zigbee2mqtt/bedroom/switch/+",
	pattern = "zigbee2mqtt/bedroom/switch/(.+)",
	on_init = function()
		tz = require('tz')
	end,
	on_match = function(payload, switch_name)
		local action = json.decode(payload).action
		local hour = gethour()

		if hour >= 22 or hour < 07 then
			log(log_tag, "it's late")

			handle_late_statemachine(action == 'on')

		else
			if action == 'on' then -- short press UP

				log(log_tag, 'turning lights on (timed)', switch_name)
				routines.register(turn_on_daytime)

			elseif action == 'off' then -- short press DOWN

				log(log_tag, 'turning lights off (manual)', switch_name)
				routines.register(turn_off)

				events.remove(main_timer)
			end
		end


		if action == 'brightness_move_up' then -- long press
			log(log_tag, 'turning lights on (bright)', switch_name)

			routines.register(turn_on_daytime)

		elseif action == 'brightness_move_down' then -- long press
			log(log_tag, 'turning lights on (bright)', switch_name)

			routines.register(turn_on_daytime)

		end
	end
}
