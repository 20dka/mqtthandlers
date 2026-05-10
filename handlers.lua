local M = {}

M.modules = {}

local function init_handlers()
	for _, handler in ipairs(M.modules) do
		if type(handler.on_init) == 'function' then
			pcall(handler.on_init)
		end
	end
end

function M.load_handlers()
	log('i', 'handlers', 'loading modules...')
	local count = 0
	for f in lfs.dir('handlers/') do
		local name = string.match(f, '(.+)%.lua$')
		if name then
			log('d', 'handlers', 'found module', f)
			local m = require('handlers/' .. name)
			m.__name = name
			table.insert(M.modules, m)
			count = count+1
		end
	end

	init_handlers()
	log('i', 'handlers', 'loaded and initialized', count, 'handlers')
end

function M.sub_handlers()
	for _, handler in ipairs(M.modules) do
		if type(handler.topic) == "string" then
			local fn = function(suback) log('d', 'MQTT', 'subscribed to topic:', handler.topic) end
			assert(client:subscribe{ topic=handler.topic, qos=0, callback=fn })
		elseif type(handler.topic) == "table" then
			for _, topic in ipairs(handler.topic) do
				local fn = function(suback) log('d', 'MQTT', 'subscribed to topic:', topic) end
				assert(client:subscribe{ topic=topic, qos=0, callback=fn })
			end
		end
	end
end

function M.parse_msg(msg)
	local exec = function (handler, str)
		if string.match(msg.topic, str) then
--			log('d', 'handlers', 'executing match for pattern', str, 'in module', handler.__name)
			local status, err = pcall(handler.on_match, msg.payload, string.match(msg.topic, str))
			if not status then
				log('e', 'handlers', 'error executing handler:', err)
			end
		end
	end

	for _, handler in ipairs(M.modules) do
		if type(handler.pattern) == "string" then
			exec(handler, handler.pattern)
		elseif type(handler.pattern) == "table" then
			for _, pattern in ipairs(handler.pattern) do
				exec(handler, pattern)
			end
		end
	end
end


return M
