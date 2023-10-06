local M = {}

local socket = require('socket') -- for .gettime()

local events = {}

function M.add(name, timeout, poll, on_expire, data)
	events[name] = {timeout=timeout, start=socket.gettime(), poll=poll, on_expire=on_expire, data=data}
end

function M.remove(name)
	if events[name] then
		events[name] = nil
		return true
	else
		return false
	end
end

function M.poll()
	for name, event in pairs(events) do
		if (socket.gettime() - event.start < event.timeout) then
			if type(event.poll) == 'function' then
				if event.poll(event.data) then
					events[name] = nil
				end
			end
		else
			if type(event.on_expire) == 'function' then
				event.on_expire(event.data)
			end
			events[name] = nil
		end
	end
end

return M
