local active_connectors = require(script.Parent.Parent.active_connectors)
local remotes = require(script.Parent.Parent.Parent.remotes)

local frames = {}
local n = 0

return function(dt)
	n += dt
	table.insert(frames, 1, os.clock())

	for i, t in frames do
		if t > os.clock() - 1 then continue end
		frames[i] = nil
	end

	for connector in active_connectors.connected do
		remotes.replicate_fps:fire(connector, #frames, dt)
	end
end
