log = require('log')

log('I', 'named module', 'hello')
log.log('w', 'named module', 'direct call')
log('E', nil, 'world')


log(nil, nil, {'a', 'table', 'of', 123})

require('logtest2')

print(#log)

for i = 1, #log do
print(log[i])
end

print()

for i = #log, 1, -1 do
print(log[i])
end


print("entries from source 'named' starting with most recent one:")
for k, v in ipairs(log.filter("named")) do
	print(v.message)
end