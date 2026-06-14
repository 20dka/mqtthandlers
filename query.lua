local M = {}
local logtag = 'MQTT:query'

local mqtt = require('mqtt')

local function dc(client)
	if not client then log('d',logtag,'client:dc nil') return end
	if client:disconnect() then
		log('d',logtag,'client:dc true')
	else
		log('d',logtag,'client:dc false')
	end
end

local function client_future(params)
	local message = nil

	local client = mqtt.client{
		uri = params.uri or 'localhost',
		clean = true,
		connector = require('mqtt.luasocket-copas'),
	}

	client:on{
		connect = function(connack)
			if connack.rc ~= 0 then
				log('e', logtag, 'MQTT connection to broker failed:', connack:reason_string(), connack)
				error(connack:reason_string())
			end

			--log('d', logtag, 'connected!')

			client:subscribe{topic=params.sub_topic}

			if params.pub_topic and params.payload then
				client:publish{topic=params.pub_topic, payload=params.payload}
				--log('d', logtag, 'published')
			end
		end,

		message = function(msg)
			assert(client:acknowledge(msg))
			message = msg
			log('i', logtag, 'got msg')
			dc(client)
		end,

		error = function(err)
			dc(client)
			error(err)
		end,
	}

	mqtt.run_sync(client)
	log('d', logtag, params.sub_topic .. ' run_sync ended')
	return message
end

-- Usage:
-- params: {uri, pub_topic, payload, sub_topic, timeout, cb, cb_err}
-- returns: result, error
function mqtt_query(params)
	local future = copas.future.addthread(client_future, params)

	local res, err = future_timeout(future, params.timeout or 5)

	if not res then
		if type(params.cb_err) == 'function' then
			params.cb_err(res)
		end
	else
		if type(params.cb) == 'function' then
			params.cb(res)
		end
	end

	return res, err
end

return M
