local function turn_off()
	client:publish{ topic="zigbee2mqtt/bulb_bathroom/set", payload=json.encode{state = "OFF"} }
	client:publish{ topic="zigbee2mqtt/bulb_bedroom_01/set", payload=json.encode{state = "OFF"} }
	client:publish{ topic="zigbee2mqtt/bulb_bedroom_02/set", payload=json.encode{state = "OFF"} }
	client:publish{ topic="zigbee2mqtt/desk_lamp/set", payload=json.encode{state = "OFF"} }
	client:publish{ topic="wled/kitchen", payload="OFF" }
end

return {
	topic = "zigbee2mqtt/switch_bathroom",
	pattern = "zigbee2mqtt/switch_bathroom",
	on_match = function(payload)
		local action = json.decode(payload).action
		if action == 'brightness_move_down' then -- long press
			turn_off()
			log('switch_bathroom', 'turning off all lights (manual)')

			events.remove('bathroom_timer')
			events.remove('bedroom_timer')
		end
	end
}
