local zigbeepath = "zigbee2mqtt/livingroom/outlet/desk_lamp"
local droidpath = "mqttdroid/desk_lamp"

local patterns = { "(zigbee2mqtt)/livingroom/outlet/desk_lamp", "(mqttdroid)/desk_lamp/set" }

return {
	topic = { zigbeepath, droidpath .."/set" },
	pattern = patterns,
	on_match = function(payload, name)
		if name == "mqttdroid" then
			log("mqttdroid", "telling the light to turn", payload)
			client:publish{ topic=zigbeepath .. "/set", payload = json.encode{state = payload} }
		elseif name == "zigbee2mqtt" then
			log("mqttdroid", "light is telling us it turned", json.decode(payload).state)
			client:publish{ topic=droidpath, payload = json.decode(payload).state }
		end
	end
}
