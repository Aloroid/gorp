--[[

	A basic scroller class.

]]

local vide = require(script.Parent.Parent.Parent.Parent.vide)

local scrolling_frame = require(script.Parent.scrolling_frame)

local create = vide.create
local source = vide.source
local derive = vide.derive
local effect = vide.effect
local cleanup = vide.cleanup

type CanBeSource<T> = T | vide.Source<T>
type infinite_scrolling_frame = {
	parent: Instance?,

	child: (index: vide.Source<number>) -> Instance,

	item_size: number,
	max_items: vide.Source<number>,

	layout: { [any]: any }?,
}

local function infinite_scrolling_frame(props: infinite_scrolling_frame)
	local canvas_position = source(Vector2.zero)
	local canvas_size = source(Vector2.zero)
	local absolute_size = source(Vector2.zero)

	local frames: { () -> () } = {}
	local indexes: { vide.Source<number> } = {}

	local max_items = props.max_items

	local lowest = derive(function()
		local position = canvas_position()

		local begin = position

		return math.clamp(math.floor(begin.Y / props.item_size) - 2, 1, math.max(1, max_items()))
	end)

	local items = derive(function() return math.ceil(absolute_size().Y / props.item_size) + 3 end)

	local frame = scrolling_frame {
		Parent = props.parent,

		Size = UDim2.fromScale(1, 1),
		CanvasSize = function()
			local max_items = props.max_items()

			if max_items == math.huge then
				return UDim2.fromOffset(0, canvas_position().Y + absolute_size().Y + props.item_size * 3)
			end

			return UDim2.fromOffset(0, props.max_items() * props.item_size)
		end,

		BackgroundTransparency = 1,

		vide.changed("AbsoluteSize", absolute_size),
		vide.changed("CanvasPosition", canvas_position),
		vide.changed("CanvasSize", canvas_size),

		props.layout,
	}

	effect(function()
		for i = 0, math.max(math.min(max_items() - 1, items()), #frames) do
			local index = lowest() + i

			if not frames[i] and i <= math.min(max_items() - 1, items()) then
				-- this is a complete hack because we cant capture inside a capture
				indexes[i] = source(index)
				frames[i] = vide.mount(function()
					local frame = create "Frame" {

						Name = function() return tostring(indexes[i]()) end,

						Size = UDim2.new(1, 0, 0, props.item_size),
						Position = function() return UDim2.fromOffset(0, (indexes[i]() - 1) * props.item_size) end,

						BackgroundTransparency = 1,

						props.child(indexes[i]),
					}

					cleanup(function() frame:Destroy() end)

					return frame
				end, frame)
			elseif frames[i] and i > math.min(max_items() - 1, items()) then
				indexes[i] = nil
				frames[i]()
				frames[i] = nil
			elseif i <= math.min(max_items() - 1, items()) then
				indexes[i](index)
			end
		end
	end)

	return frame
end

return infinite_scrolling_frame
