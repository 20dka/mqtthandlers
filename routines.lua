local M = {}

local socket = require('socket') -- for .gettime()

local routines = {}

function M.register(fn, name, ...)
	local co = coroutine.create(fn)
	if name then
		routines[name] = co

		if ... then
			coroutine.resume(co, ...)
		end
	else
		table.insert(routines, co)
	end
end

function M.remove(name)
	routines[name] = nil
end

function M.tick()
	for name, routine in pairs(routines) do
		if coroutine.status(routine) ~= "dead" then
			coroutine.resume(routine)
		end
		if coroutine.status(routine) == "dead" then
			print("routine dead", name)
			routines[name] = nil
		end
	end
end

function M.sleep(s)
	local start = socket.gettime()
	while socket.gettime() < (start + s) do
		coroutine.yield()
	end
end

function M.zigbeeData(path, timeout)
	if not _G.zigbeestate then return nil end

	local start = socket.gettime()

	_G.zigbeestate[path] = nil

	while not _G.zigbeestate[path] and socket.gettime() < (start + s) do
		coroutine.yield()
	end

	return _G.zigbeestate[path]
end

return M
