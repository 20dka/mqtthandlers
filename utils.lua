local consoleTag = {"[\27[42;93m", "\27[0m]"}
local consoleTagError = {"[\27[101;93m", "\27[0m]"}

config = require('config')

json = require('json')
lfs = require('lfs')
log = require('log')
socket = require('socket')
query = require('query')

do -- turn arguments into hashmap
	_G.arg = _G.arg or {}
	for k, v in ipairs(_G.arg) do
		local name, val = string.match(v, '(.+)%=(.+)')
		if val then
			_G.arg[name] = val
		else
			_G.arg[v] = true
		end
	end
end


function dump(t, header)
	if header then
		print('dump', header)
	end
	for k, v in pairs(t) do
		if type(v) == 'table' then
			dump(v, k)
		else
			print(k, v)
		end
	end
end

function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function splitString(s, delimiter)
	local result = {}
	delimiter = delimiter or " "
	for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

local accents = {
	['á'] = 'a',
	['ó'] = 'o',
	['ö'] = 'o',
	['ő'] = 'o',
	['ú'] = 'u',
	['ü'] = 'u',
	['ű'] = 'u',
	['í'] = 'i',
	['é'] = 'e'
}

function deaccentize(s)
	return (string.gsub(s, '(%a+)', accents))
end

function future_timeout(future, timeout)
	local start = socket.gettime()
	while socket.gettime() < (start + timeout) and not future:try() do
		copas.pause(0)
	end

	local status, res = future:try()
	if future:cancel() or status == 'error' then
		log('e', 'future_timeout', 'future errored or timed out')
		return nil, res
	else
		return res
	end
end
