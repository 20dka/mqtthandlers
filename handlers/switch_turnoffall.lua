local function turn_off()
	client:publish{ topic="zigbee2mqtt/bathroom/light/bulb1/set", payload=json.encode{state = "OFF"} }
	client:publish{ topic="zigbee2mqtt/bedroom/light/bulb1/set", payload=json.encode{state = "OFF"} }
	client:publish{ topic="zigbee2mqtt/bedroom/light/bulb2/set", payload=json.encode{state = "OFF"} }
	client:publish{ topic="zigbee2mqtt/livingroom/outlet/desk_lamp/set", payload=json.encode{state = "OFF"} }
	client:publish{ topic="zigbee2mqtt/kitchen/outlet/hood/set", payload=json.encode{state = "OFF"} }
	client:publish{ topic="wled/kitchen", payload="OFF" }
end

return {
	topic = "zigbee2mqtt/kitchen/switch/negygombos",
	pattern = "zigbee2mqtt/kitchen/switch/negygombos",
	on_match = function(payload)
		local action = json.decode(payload).action
		if action == 'brightness_move_down' then -- long press
			turn_off()
			log('switch_turnoffall', 'turning off all lights (manual)')

			events.remove('bathroom_timer')
			events.remove('bedroom_timer')
			events.remove('kitchen_strip_timer')
		end
	end
}
