local bulb = "zigbee2mqtt/bathroom/light/bulb1/set"

local function turn_on(brightness)
	client:publish{ topic=bulb, payload=json.encode{state ="ON", brightness = brightness} }
end

local function turn_off()
	client:publish{ topic=bulb, payload=json.encode{state = "OFF"} }
end

local BRIGHTNESS_DIM = 2

return {
	topic = "zigbee2mqtt/bathroom/motion/primary",
	pattern = "zigbee2mqtt/bathroom/motion/primary",
	on_match = function(payload)
		local occupied = json.decode(payload).occupancy
		if occupied then
			if not events.get("bathroom_timer") then
				turn_on(BRIGHTNESS_DIM)
				log('motion_bathroom', 'turning light on (dim) (timed)')

				events.add('bathroom_timer', 60*20, nil, function()
					turn_off()
					log('motion_bathroom', 'turning light off (timer ran out)')
				end)
			elseif events.extend("bathroom_timer", 60*20) then
				log('motion_bathroom', 'extending light')
			end
		end
	end
}
