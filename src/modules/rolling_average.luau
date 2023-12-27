local gorp = require(script.Parent.Parent.gorp)
local rolling_average = {}

function rolling_average.new(max: number?): gorp.RollingAverage
	local last = max or 50
	local n = table.create(last + 1)
	local updated = false
	local self = { values = n } :: gorp.RollingAverage

	function self:add(value: number)
		table.insert(self.values, 1, value)
		table.remove(self.values, last + 1)
		updated = true
	end

	function self:updated()
		if updated then
			updated = false
			return true
		end
		return false
	end

	function self:average()
		local total = 0

		for _, n in n do
			total += n
		end

		return total / last
	end

	return self
end

return rolling_average
