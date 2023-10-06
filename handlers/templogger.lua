local influxdb = nil

return {
	topic = 'EspThermostat/+/logTemp',
	pattern = 'EspThermostat/(.-)/logTemp$',
	on_init = function() influxdb = require('influxdb') end,
	on_match = function(payload, room)
		log('templogger', 'received temperature:', room, payload)
		local success, err = influxdb.write(room, payload)
		if not success then
			log('e', 'influxdb failed to write to db:', err)
		end
	end,
}
