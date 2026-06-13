trigger: connected to broker

code:
local topic = "devices/netio_deer/messages/pc_sleep/devicebound"

log("Lua script 'setupMqtt' started")

devices.system.MqttLuaSubscribe{topic = topic}
logf("Subscribed to MQTT topic '%s'", topic)
