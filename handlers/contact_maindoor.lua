local DOOR_CLOSED, DOOR_OPEN = true, false
local MOTIONPATH = "kitchen/motion/primary"

return {
	topic = "zigbee2mqtt/kitchen/contact/door",
	pattern = "zigbee2mqtt/kitchen/contact/door",
	on_match = function(payload)
		local door = json.decode(payload)

		local leaving = zigbeestate[MOTIONPATH] and (zigbeestate[MOTIONPATH].data.occupancy == true)

		if door.contact == DOOR_OPEN and not leaving then
			print('arrived home, turn stuff on')
		elseif door.contact == DOOR_CLOSED and leaving then
			print('leaving, turn stuff off')
		end
	end
}
