local socket = nil
local strip_timer = 'kitchen_strip_timer'
local strip_dim_timer = 'kitchen_strip_brightness_timer'

local function turn_on(brightness)
	client:publish{ topic="wled/kitchen", payload=(brightness and tostring(brightness) or "ON") }
end

local function turn_off()
	client:publish{ topic="wled/kitchen", payload="OFF" }
end

local function timer_ran_out()
	turn_off()
	log('i', 'switch_kitchen', 'turning light strip off (timer ran out)')
end

local function timer_dim()
	local now = socket.gettime()
	local delta = now - dim_last
	if delta > 0.5 then
		client:publish{ topic="wled/kitchen/api", payload=string.format('{"bri":"~%s30"}', dim_direction and '-' or '') }
		dim_last = now
	end
end

return {
	on_init = function()
		socket = require('socket')
	end,
	topic = "zigbee2mqtt/kitchen/switch/+",
	pattern = "zigbee2mqtt/kitchen/switch/(.+)",
	on_match = function(payload, switch_name)
		local action = json.decode(payload).action
		local brightness_dir = string.match(action, "brightness_move_(%a+)")

		if action == 'on' then
			turn_on()
			log('i', 'switch_kitchen', 'turning ON strip (timed)')

			events.add(strip_timer, 60*60*4, nil, timer_ran_out)

		elseif action == 'off' then
			turn_off()
			log('i', 'switch_kitchen', 'turning OFF strip (timed)')

			events.remove(strip_timer)

		elseif brightness_dir then
			dim_last = socket.gettime()
			dim_direction = brightness_dir == 'down'
			events.add(strip_dim_timer, 5, timer_dim, nil)

			log('i', 'switch_kitchen', 'beginning kitchen lights dimming, going', dim_direction and 'down' or 'up')

		elseif action == 'brightness_stop' then
			events.remove(strip_dim_timer)

			log('i', 'switch_kitchen', 'removing lights dimming timer')
		end
	end
}
