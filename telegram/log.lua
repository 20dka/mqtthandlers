local M = {
	access = {'deer', 'lo'},
	prefix = 'log'
}

local default_logcount = 5

local fmt = telegram.api.fmt

local function msg_format(entry)
	local msg = ""

	local date_now = math.floor(os.time() / (60*60*24))
	local date_entry = math.floor(entry.time / (60*60*24))

	if date_entry == date_now then
		msg = os.date('%H:%M:%S', entry.time)
	elseif date_entry == date_now-1 then
		msg = os.date('Yesterday %H:%M:%S', entry.time)
	else
		msg = os.date('%Y/%m/%d %H:%M:%S', entry.time)
	end

	return string.format('%s [%s] [%s]: %s', msg, fmt.bold(entry.level, 'HTML'), fmt.code(entry.source), entry:as_message())
end

function M.on_message(cmd)
	local source, count = tostring(cmd.args[1]), tonumber(cmd.args[2]) or default_logcount
	local messages = log.filter(source, count)
	local output = ""

	if messages then
		for k,v in ipairs(messages) do
			output = output .. msg_format(v) .. '\n'
		end
	else
		output = string.format("No log entries from source '%s' found.", source)
	end

	telegram.api.send_message(cmd.context.chat.id, output, { parse_mode = 'HTML' })
end

return M
