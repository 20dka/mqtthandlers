require('utils')

local mqtt = require('mqtt')

events = require('timed_event')

handlers = require('handlers')

local host = _G.arg['--hostname'] or 'localhost'
local clientid = _G.arg['--clientid'] or 'luabridge'

-- mqtt
client = mqtt.client{
	uri = host,
	id = clientid,
	clean = true,
	reconnect = true,
}

handlers.load_handlers()

client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			log('e', "mqtt connection to broker failed:", connack:reason_string(), connack)
			return
		end
		log("mqtt", "connected:", connack) -- successful connection

		handlers.sub_handlers()
	end,

	message = function(msg)
		assert(client:acknowledge(msg))
		handlers.parse_msg(msg)
	end,

	error = function(err) log('e', "MQTT client error:", err) end,
}


mqtt.run_ioloop(client, events.poll)
