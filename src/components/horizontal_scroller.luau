--[[

	A basic horizontal scroller class.

]]

local actions = require(script.Parent.Parent.actions)
local vide = require(script.Parent.Parent.Parent.vide)

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

		return math.clamp(
			math.floor(begin.X / props.item_size) - 2,
			1,
			math.max(1, max_items())
		)
	end)

	local items = derive(
		function() return math.ceil(absolute_size().X / props.item_size) + 3 end
	)

	local frame = scrolling_frame {
		Parent = props.parent,

		Size = UDim2.fromScale(1, 1),
		CanvasSize = function()
			local max_items = props.max_items()

			if max_items == math.huge then
				return UDim2.fromOffset(
					0,
					canvas_position().X
						+ absolute_size().X
						+ props.item_size * 3
				)
			end

			return UDim2.fromOffset(
				(props.max_items() - 1) * props.item_size,
				0
			)
		end,

		BackgroundTransparency = 1,

		actions.output("AbsoluteSize", absolute_size),
		actions.output("CanvasPosition", canvas_position),
		actions.output("CanvasSize", canvas_size),

		props.layout,
	}

	effect(function()
		--print(items(), #frames)
		for i = 0, math.max(math.min(max_items() - 1, items()), #frames) do
			local index = lowest() + i

			if not frames[i] and i <= math.min(max_items() - 1, items()) then
				-- this is a complete hack because we cant capture inside a capture
				indexes[i] = source(index)
				frames[i] = vide.mount(function()
					local frame = create "Frame" {

						Name = function() return tostring(indexes[i]()) end,

						Size = UDim2.new(0, props.item_size, 1, 0),
						Position = function()
							return UDim2.fromOffset(
								(indexes[i]() - 1) * props.item_size,
								0
							)
						end,

						BackgroundTransparency = 1,

						props.child(indexes[i]),
					}

					cleanup(function() frame:Destroy() end)

					return frame
				end, frame)

				--print("creating for", i)
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
