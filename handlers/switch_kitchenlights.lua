local strip_timer = 'kitchen_strip_timer'

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

return {
	topic = "zigbee2mqtt/kitchen/switch/negygombos",
	pattern = "zigbee2mqtt/kitchen/switch/negygombos",
	on_match = function(payload)
		local action = json.decode(payload).action
		if action == 'arrow_left_click' or action == 'arrow_right_click' then -- short press (either side)
			turn_on('T') -- toggle

			log('switch_kitchen', 'toggling strip (timed)')

			events.add(strip_timer, 60*60*4, nil, timer_ran_out)
		end
	end
}
