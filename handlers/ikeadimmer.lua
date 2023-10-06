return {
	topic = "zigbee2mqtt/IKEAdimmer",
	pattern = "zigbee2mqtt/IKEAdimmer",
	on_match = function(payload)
		local action = json.decode(payload).action
		if action == 'off' then
			client:publish{ topic="EspRelay/In", payload='off' }
			log('IKEAdimmer', 'turning relay off')

			events.remove('relaytimer')
		end

		if action == 'brightness_move_up' then -- long press
			client:publish{ topic="EspRelay/In", payload='on' }
			log('IKEAdimmer', 'turning relay on (permanently)')

			events.remove('relaytimer')
		end

		if action == 'on' then -- short press
			client:publish{ topic="EspRelay/In", payload='on' }
			log('IKEAdimmer', 'turning relay on (for 4h)')

			events.add('relaytimer', 60*60*4, nil, function()
				client:publish{ topic="EspRelay/In", payload='off' }
				log('IKEAdimmer', 'turning relay off (timer ran out)')
			end)
		end
	end
}
