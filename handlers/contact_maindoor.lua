local DOOR_CLOSED, DOOR_OPEN = true, false
local MOTIONPATH = "kitchen/motion/primary"

return {
	topic = "zigbee2mqtt/kitchen/contact/door",
	pattern = "zigbee2mqtt/kitchen/contact/door",
	on_match = function(payload)
		local door = json.decode(payload)

		log('i', 'main door', door.contact == DOOR_OPEN and 'opened' or 'closed')
	end
}
