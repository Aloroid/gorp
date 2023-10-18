local rolling_average = {}

function rolling_average.new(max: number?)
	local last = max or 50
	local n = table.create(last + 1)
	local self = { values = n }

	function self:add(value: number)
		table.insert(n, 1, value)
		table.remove(n, last + 1)
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
