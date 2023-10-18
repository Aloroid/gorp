local rolling_average = {}

function rolling_average.new()
	local self = {}
	local n = table.create(51)

	function self:add(value: number)
		table.insert(n, 1, value)
		table.remove(n, 51)
	end

	function self:average()
		local total = 0

		for _, n in n do
			total += n
		end

		return total / 50
	end

	return self
end

return rolling_average
