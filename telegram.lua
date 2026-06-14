local M = { api = require('telegram-bot-lua'), modules = {} }

local copas = require('copas')


local proxy = require('telegram.proxy')
local tg_log = require('telegram.log')

local function init_handlers()
	for _, handler in ipairs(M.modules) do
		if type(handler.on_init) == 'function' then
			pcall(handler.on_init)
		end
	end
end

local function load_handlers()
	log('i', 'Telegram', 'loading modules...')
	local count = 0
	for f in lfs.dir('telegram/') do
		local name = string.match(f, '(.+)%.lua$')
		if name then
			log('d', 'Telegram', 'found module', f)
			local m = require('telegram/' .. name)
			m.__name = name
			table.insert(M.modules, m)
			count = count+1
		end
	end

	init_handlers()
	log('i', 'Telegram', 'loaded and initialized', count, 'bot command handlers')
end


-- Set up the bot with concurrent update processing.
-- Each update is dispatched to its own coroutine so a slow handler
-- won't block processing of other updates.
-- from: src/async.lua:api.async.run()
function M.setup(opts)
	log('i', 'Telegram','connecting to Telegram...')

	local ok, err = pcall(M.api.configure, config.telegram.API_TOKEN)

	if ok then
		log('i', 'Telegram', 'connected! Username:', '@'..M.api.info.name)
	else
		log('e', 'Telegram', 'client error:', err)
		return
	end

	opts = opts or {}
	local limit = tonumber(opts.limit) or 1
	local timeout = tonumber(opts.timeout) or 0
	local offset = tonumber(opts.offset) or 0
	local allowed_updates = opts.allowed_updates

	-- Swap request function to use async version within copas context
	M.api.request = M.api.async.request
	M.api.async._running = true

	copas.addthread(function()

		if proxy.access == 'deer' then
			--M.api.set_my_commands({{command='/'..proxy.prefix, description='Proxy a message to another user'}}, {type='chat', chat_id=157537807})
		end

		while M.api.async._running do
			local ok, updates = pcall(M.api.get_updates,{
				timeout = timeout,
				offset = offset,
				limit = limit,
				allowed_updates = allowed_updates
			})
			if ok and updates and type(updates) == 'table' and updates.result then
				for _, v in pairs(updates.result) do
					-- Each update gets its own coroutine
					copas.addthread(function()
						local ok, err = pcall(M.api.process_update, v)
						if not ok then
							print('Update handler error: ' .. tostring(err))
						end
					end)
					offset = v.update_id + 1
				end
			end
		end
	end)

	load_handlers()

	copas.running = true
end

function M.tick()
	copas.step()
end



function M.api.on_supergroup_message(message)
	M.api.send_message(message.chat.id, string.format('@%s said:%s', 
		message.from.username, message.text))
end
M.api.on_group_message = M.api.on_supergroup_message

local function has_command_access(module, context)
	local access = module.access
	if type(access) == 'string' then
		access = { access }
	end

	for k, v in ipairs(access) do
		local possible_id = nil

		if type(v) == 'string' then
			possible_id = config.telegram.aliases[v]
		elseif type(v) == 'number' then
			possible_id = v
		else
			log('w', 'Telegram', 'unknown access type in module', module.__name)
		end

		if possible_id and possible_id == context.from.id then
			return true
		end
	end

	return false
end

function M.api.on_private_message(message)
	if message.text then
		M.api.send_message(message.chat.id, 'You said: ' .. message.text)
	end

	local cmd = M.api.extract_command(message)
	if cmd then
		cmd.context = messa1ge

		for k, v in ipairs(M.modules) do
			if cmd.command == v.prefix then
				if has_command_access(v, message) then
					v.on_message(cmd)
				else
					log('w', 'Telegram', 'user', string.format('@%s[%d]', 
						message.from.username, message.from.id), 'tried to use command', v.prefix)
				end
			end
		end
	end
end

function M.api.on_message(message)
	local content = message.text or message.image or '<unknown>'
	log('i', 'Telegram', 'message received', string.format('@%s[%d]: %s', 
		message.from.username, message.from.id, content))
end



return M
