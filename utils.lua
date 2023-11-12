
local consoleTag = {"[\27[42;93m", "\27[0m]"}
local consoleTagError = {"[\27[101;93m", "\27[0m]"}

json = require('json')
lfs = require('lfs')

do -- turn arguments into hashmap
	for k, v in ipairs(_G.arg) do
		local name, val = string.match(v, '(.+)%=(.+)')
		if val then
			_G.arg[name] = val
		else
			_G.arg[v] = true
		end
	end
end

function log(topic, msg, ...)
	local tags = topic == 'e' and consoleTagError or consoleTag
	if not msg then tags = {'', ''} end

	local timestamp = arg and arg['--dont-log-time'] and '' or os.date('%Y/%m/%d %H:%M:%S ')

	local s = table.concat{timestamp, tags[1], topic, tags[2], ''}
	print(s, msg, ...)
end

function dump(t, header)
	if header then
		log(header)
	end
	for k, v in pairs(t) do
		print(k, v)
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
