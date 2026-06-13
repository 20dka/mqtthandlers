trigger: received on subscibed topic

code:
local sub_topic = "devices/netio_deer/messages/pc_sleep/devicebound"
local pub_topic = "devices/netio_deer/messages/pc_sleep"
local pc = 1
local timeout_sec_default = 120
local power_threshold = 5 --in Watts

--local running = false

local function getpower()
	return devices.system['output' .. tostring(pc) .. '_consumption']
end

local function eep()
	devices.system.MqttPublish{topic=pub_topic,payload="done"}
	devices.system.SetOut{output = pc, value = false}
end








log("MQTT message received!")

if event.args.topic ~= sub_topic then
	logf("Unknown topic '%s', ignoring", event.args.topic)
	return
end

local function run(timeout_sec)
	log("Running shutdown check")
	devices.system.MqttPublish{topic=pub_topic,payload="started"}
	_G.running = true
	loop(timeout_sec or timeout_sec_default)
end

local function cancel()
	log("Cancelling shutdown check")
	devices.system.MqttPublish{topic=pub_topic,payload="cancelling"}
	_G.running = false
end

if tonumber(event.args.payload) then
	run(tonumber(event.args.payload))
elseif event.args.payload == 'go' then
	run()
elseif event.args.payload == 'cancel' then
	cancel()
elseif event.args.payload == 'toggle' then
	logf("toggling script. Running? %s", _G.running and 'y' or 'n')
	if _G.running then
		cancel()
	else
		run()
	end
else
	logf("unknown payload '%s'", event.args.payload)
end



function loop(cnt)
	if not _G.running then
		log("PC shutdown script cancelled")
		devices.system.MqttPublish{topic=pub_topic,payload="cancelled"}
		return
	end

	local power = getpower()
	logf('PC Consumption: %dW', power)

	if power < power_threshold then
		log("Consumption sufficently low, cutting power")
		eep()
		_G.running = false
		return
	end

	if cnt > 0 then
		delay(1, function()
			loop(cnt-1)
		end)
	else
		logf("System did not power down in time (%d seconds)", timeout_sec)
		devices.system.MqttPublish{topic=pub_topic,payload="timeout"}
		_G.running = false
	end
end
