local M = {}
local MT = {}

local loghistory = {}

local source_pattern = '^@[%.%/]*([%w%s%-_/]+)%.lua$'

log_tags = {
	--D = {},
	I = {"\27[42;1m", "\27[0m"},
	W = {"\27[43;1m", "\27[0m"},
	E = {"\27[41;1m", "\27[0m"},
}

local log_entry = {mt = {}}

log_entry.mt.__index = log_entry

local function timestamp(t)
	return os.date('%Y/%m/%d %H:%M:%S ', t)
end

function log_entry:as_message()
	return type(self.message) == 'table' and table.concat(self.message, ' ') or tostring(self.message)
end

function log_entry.mt:__tostring()
	return string.format('%s[%s] [%s]: %s', timestamp(self.time), self.level, self.source, self:message())
end

function log_entry:as_system_log(no_time, no_color)
	local timestamp = (arg['--dont-log-time'] or no_time) and '' or timestamp(self.time)
	local level = self.level
	local source = self.source
	local msg = type(self.message) == 'table' and table.concat(self.message, ' ') or tostring(self.message)

	if log_tags[self.level] and not arg['--no-color'] and not no_color then
		level = log_tags[self.level][1] .. level .. log_tags[self.level][2]
		source = log_tags[self.level][1] .. source .. log_tags[self.level][2]
	end

	return string.format('%s[%s] [%s]: %s', timestamp, level, source, msg)
end

function log_entry:new(level, source, ...)
	level = level or 'I'
	local aa = debug.getinfo(4).source
	source = source or string.match(aa, source_pattern) or 'unknown'
	source = string.gsub(source, '/', '_')

	local message = {...}
	if #message < 2 then message = message[1] end

	local entry = { level = level:upper(), source = source, time = os.time(), message = message }
	return setmetatable(entry, self.mt)
end

local function log_actual(...)
	local entry = log_entry:new(...)
	table.insert(loghistory, entry)

	print(entry:as_system_log())
end

-- level, source, <message vararg> ...
function M.log(...)
	log_actual(...)
end

function M.logcount()
	return #loghistory
end

function M.get_log(idx)
	local index = M.logcount() - math.max(0, idx-1)
	return loghistory[index]
end

function M.filter(source, count)
	source = source:lower()
	local res = {}

	for idx = 1, M.logcount() do
		local entry = M.get_log(idx)
		if string.match(entry.source:lower(), source) then
			table.insert(res, entry)
			if count and #res >= count then
				return res
			end
		end
	end

	return next(res) and res or nil
end

MT.__call = function(_, ...) log_actual(...) end
MT.__len = M.logcount
MT.__index = function (_, idx) return M.get_log(idx) end

return setmetatable(M, MT)
