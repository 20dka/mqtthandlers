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
	log('switch_kitchen', 'turning light strip off (timer ran out)')
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
	topic = "zigbee2mqtt/kitchen/switch/negygombos",
	pattern = "zigbee2mqtt/kitchen/switch/negygombos",
	on_match = function(payload)
		local dir, action = string.match(json.decode(payload).action, "arrow_(%a+)_(%a+)")

		if action == 'click' then -- short press (either side)
			turn_on('T') -- toggle

			log('switch_kitchen', 'toggling strip (timed)')

			events.add(strip_timer, 60*60*4, nil, timer_ran_out)
		elseif action == 'hold' then
			dim_last = socket.gettime()
			dim_direction = dir == 'left'
			events.add(strip_dim_timer, 20, timer_dim, nil)

			log('switch_kitchen', 'beginning kitchen lights dimming, going', dim_direction and 'down' or 'up')

		elseif action == 'release' then
			events.remove(strip_dim_timer)

			log('switch_kitchen', 'removing dimming timer')
		end
	end
}
