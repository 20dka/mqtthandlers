local function turn_on(brightness)
	client:publish{ topic="zigbee2mqtt/bulb_bathroom/set", payload=json.encode{state ="ON", brightness = brightness}}
end

local function turn_off()
	client:publish{ topic="zigbee2mqtt/bulb_bathroom/set", payload=json.encode{state = "OFF"}}
end

return {
	topic = "zigbee2mqtt/switch_bathroom",
	pattern = "zigbee2mqtt/switch_bathroom",
	on_match = function(payload)
		local action = json.decode(payload).action
		if action == 'on' then
			turn_on(2)
			log('switch_bathroom', 'turning light on (dim) (timed)')

			events.add('bathroom_timer', 60*60*1, nil, function()
				turn_off()
				log('switch_bathroom', 'turning light off (timer ran out)')
			end)
		elseif action == 'brightness_move_up' then -- long press
			turn_on(254)
			log('switch_bathroom', 'turning light on (bright)')

			events.remove('bathroom_timer')
		elseif action == 'off' then -- short press
			turn_off()
			log('switch_bathroom', 'turning light off (manual)')

			events.remove('bathroom_timer')
		end
	end
}
