local function turn_on(brightness)
	client:publish{ topic="zigbee2mqtt/bulb_bathroom/set", payload=json.encode{state ="ON", brightness = brightness}}
end

local function turn_off()
	client:publish{ topic="zigbee2mqtt/bulb_bathroom/set", payload=json.encode{state = "OFF"}}
end

return {
	topic = "zigbee2mqtt/motion_bathroom",
	pattern = "zigbee2mqtt/motion_bathroom",
	on_match = function(payload)
		local occupied = json.decode(payload).occupancy
		if occupied then
			turn_on(2)
			log('motion_bathroom', 'turning light on (dim) (timed)')

			events.add('bathroom_timer', 60*20, nil, function()
				turn_off()
				log('motion_bathroom', 'turning light off (timer ran out)')
			end)
		else
			turn_off()
			log('motion_bathroom', 'turning light off (no longer occupied)')

			events.remove('bathroom_timer')
		end
	end
}
