require('utils')

copas = require('copas')

local mqtt = require('mqtt')

events = require('timed_event')

handlers = require('handlers')

routines = require('routines')

local host = _G.arg['--hostname'] or 'localhost'
local clientid = _G.arg['--clientid'] or 'luabridge'

-- mqtt
client = mqtt.client{
	uri = host,
	id = clientid,
	clean = true,
	connector = require('mqtt.luasocket-copas'),
}

handlers.load_handlers()

client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			log('e', 'MQTT', 'MQTT connection to broker failed:', connack:reason_string(), connack)
			return
		else
			log('i', 'MQTT', 'connected!')
		end

		handlers.sub_handlers()
	end,

	message = function(msg)
		assert(client:acknowledge(msg))
		handlers.parse_msg(msg)
	end,

	error = function(err) log('e', 'MQTT', 'client error:', err) end,
}

copas.addnamedthread("MQTT_thread", function()
	log('d', 'MQTT', 'Starting client thread...')

	while true do -- to enable reconnecting
		mqtt.run_sync(client)
	end
end)

copas.addthread(function()
	while true do
		events.poll()
		copas.pause()
	end
end)

copas.addthread(function()
	while true do
		routines.tick()
		copas.pause()
	end
end)

copas.loop()
