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
	log('handler', 'loading modules...')
	for f in lfs.dir('handlers/') do
		local name = string.match(f, '(.+)%.lua$')
		if name then
			log('handler', 'found module', f)
			local m = require('handlers/' .. name)
			m.__name = name
			table.insert(M.modules, m)
		end
	end

	init_handlers()
end

function M.sub_handlers()
	fn = function(suback) log("mqtt", "subscribed to topic:", suback) end

	for _, handler in ipairs(M.modules) do
		assert(client:subscribe{ topic=handler.topic, qos=0, callback=fn })
	end
end

function M.parse_msg(msg)
	for _, handler in ipairs(M.modules) do
		if string.match(msg.topic, handler.pattern) then
			log('handler','executing match for pattern', handler.pattern, 'in module', handler.__name)
			local status, err = pcall(handler.on_match, msg.payload, string.match(msg.topic, handler.pattern))
			if not status then
				log('e', 'error executing handler:', err)
			end
		end
	end
end


return M