--[[

	Provides a horizontal resizeable bar

]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local background = require(script.Parent.background)
local border = require(script.Parent.border)
local text = require(script.Parent.text)

local create = vide.create
local source = vide.source
local indexes = vide.indexes
local derive = vide.derive
local effect = vide.effect
local cleanup = vide.cleanup

-- constants used as fallbacks
local MAX_PIXELS_OFFSET = 32

local before = source(0)
local after = source(1)

type ResizeableBar = {

	meaning: vide.Source<{ string }>,
	min_sizes: vide.Source<{ vide.Source<number>? }>?,
	sizes: vide.Source<{ vide.Source<number> }>,

	splits: vide.Source<{ vide.Source<number> }>?,
	base_splits: { number }?,
}

local function resizeable_bar(props: ResizeableBar)
	local meaning = props.meaning
	local sizes = props.sizes
	local min_sizes = props.min_sizes or source({}) :: never

	local absolute_size = source(Vector2.one)
	local absolute_position = source(Vector2.one)

	local total = derive(function() return #meaning() end)

	local old_splits = {}
	local splits_user = (props.splits :: never) or source({})
	local splits = derive(function()
		local splits = {}

		for i = 1, total() - 1 do
			local old_split = vide.read(old_splits[i])
			splits[i] = source(math.min(old_split or 1, i / total()))
			old_splits[i] = splits[i]
		end

		old_splits = splits
		splits_user(splits)
		return splits
	end)

	for i, split in (props.base_splits :: never) or {} do
		splits()[i](split)
	end

	local function get_size(index: number)
		local split_before = splits()[index - 1] or before :: never
		local split_after = splits()[index] or after :: never

		local size = split_after() - split_before()
		return size
	end

	local function get_min_size(i: number)
		local min_size = min_sizes()[i]
		return min_size and min_size() or 0.01
	end

	effect(function()
		local new = setmetatable({}, { __index = function() return source(0) end })

		for i = 1, total() do
			min_sizes()[i] = min_sizes()[i] or source(0.01)

			cleanup(vide.mount(function()
				new[i] = derive(function() return get_size(i) end)
			end))
		end

		sizes(new :: any)
	end)

	local down = false
	local updating = 0

	return create "TextButton" {
		Size = UDim2.new(1, 0, 0, 32),

		BackgroundColor3 = style.background,
		Text = "",

		indexes(meaning, function(value, index: number)
			local store = style.corner_radius
			style.corner_radius = UDim.new()
			local button = background {

				BackgroundColor3 = style.button,

				Position = function()
					local split_before = splits()[index - 1] or before :: never

					return UDim2.fromScale(split_before(), 0)
				end,

				Size = function()
					local size = get_size(index)

					return UDim2.new(size, 0, 1, 0)
				end,

				text {
					layout = {
						Size = UDim2.fromScale(1, 1),
						TextTruncate = Enum.TextTruncate.AtEnd,
					},

					text = value,
				},

				border {},
			}
			style.corner_radius = store
			return button
		end),

		vide.changed("AbsoluteSize", absolute_size),
		vide.changed("AbsolutePosition", absolute_position),

		MouseButton1Down = function(x: number)
			-- find the nearest split
			x -= absolute_position().X
			local absolute_size = absolute_size()
			local nearest = -1
			for i, location in splits() do
				local absolute_x = absolute_size.X * location()
				if math.abs(x - absolute_x) > MAX_PIXELS_OFFSET then continue end

				nearest = i
			end

			down = nearest ~= -1
			updating = nearest
		end,

		MouseButton1Up = function() down = false end,

		cleanup(RunService.Heartbeat:Connect(function()
			local x = UserInputService:GetMouseLocation().X

			x -= absolute_position().X
			if down == false then return end
			down = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) == true

			local relative = x / absolute_size().X
			local current = splits()[updating]()
			local left_to_move = relative - current

			if left_to_move > 0 then
				for i = updating, total() - 1, 1 do
					local min_size = get_min_size(i + 1)
					local size = get_size(i + 1)

					local new_size = math.max(size - left_to_move, min_size)
					local difference = size - new_size

					splits()[i](splits()[i]() + difference)
					left_to_move -= difference

					if left_to_move == 0 then break end
				end
			else
				for i = updating, 1, -1 do
					local min_size = get_min_size(i)

					local size = math.max(get_size(i), min_size) -- this is changing, which it isnt supposed to do

					local new_size = math.max(size + left_to_move, min_size)
					local difference = new_size - size

					splits()[i](splits()[i]() + difference)
					--assert((new_size + difference) == get_size(i - 1))
					left_to_move -= difference

					if left_to_move == 0 then break end
				end
			end
		end)),
	}
end

return resizeable_bar
