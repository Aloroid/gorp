local container = require(script.Parent.container)
local line = require(script.Parent.line)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local read = vide.read
local untrack = vide.untrack
local source = vide.source
local indexes = vide.indexes
local derive = vide.derive
local changed = vide.changed

type c<T> = T | () -> T
type graph = {

	values: c<{ c<number> }>,

	max_y: c<number>?,

	layout: vide.vFrame?,
}

local function wrap<T>(t: c<T>): () -> T
	return function()
		return read(t)
	end
end

return function(props: graph)
	local max_y = derive(function()
		local max = 0
		for key, value: c<number> in read(props.values) do
			max = math.max(max, read(value))
		end
		return max
	end)
	local min_y = derive(function()
		local min = 0
		for key, value: c<number> in read(props.values) do
			min = math.min(min, read(value))
		end
		return min
	end)
	local function delta()
		return max_y() - min_y()
	end
	local max_x = derive(function()
		return #read(props.values)
	end)

	local absolute_size = source(Vector2.zero)
	local wrapped = wrap(props.values)

	return container {

		indexes(wrapped, function(value: () -> c<number>, index: number)
			local previous = function(): c<number>
				return untrack(wrapped)[index - 1]
			end

			return line {

				absolute_size = absolute_size,

				pa = derive(function()
					if index == 1 then return UDim2.new() end
					return UDim2.fromScale(
						(index - 2) / (max_x() - 1),
						1 - ((read(previous()) :: number) - min_y()) / delta()
					)
				end),
				pb = derive(function()
					if index == 1 then return UDim2.new() end
					return UDim2.fromScale(
						(index - 1) / (max_x() - 1),
						1 - ((read(value()) :: number) - min_y()) / delta()
					)
				end),
			}
		end),

		changed("AbsoluteSize", absolute_size),

		props.layout,
	}
end
