local vide = require(script.Parent.Parent.Parent.Parent.vide)

local create = vide.create
local source = vide.source
local derive = vide.derive
local read = vide.read

local function from_udim2_to_vector(value: UDim2, parent_size: Vector2)
	return Vector3.new(value.X.Offset + value.X.Scale * parent_size.X, value.Y.Offset + value.Y.Scale * parent_size.Y)
end

type c<T> = T | () -> T
type line = {

	color: c<Color3>?,
	thickness: c<number>?,

	absolute_size: c<Vector2>?,

	-- point a
	pa: c<UDim2>,
	-- point b
	pb: c<UDim2>,
}

local function line(props: line)
	local thickness = props.thickness or 3

	local ref = source() :: vide.Source<Instance>
	local update = source()

	local ancestor_gui = derive(function()
		update()
		if not ref() then return nil :: GuiBase2d? end
		return ref():FindFirstAncestorWhichIsA("GuiBase2d")
	end)

	local absolute_size = props.absolute_size
		or function()
			update()
			local ancestor = ancestor_gui()
			if not ancestor then return Vector2.zero end
			return ancestor.AbsoluteSize
		end

	local point_a = derive(function()
		return from_udim2_to_vector(read(props.pa), read(absolute_size))
	end)
	local point_b = derive(function()
		return from_udim2_to_vector(read(props.pb), read(absolute_size))
	end)
	local middle = derive(function()
		return (point_a() + point_b()) / 2
	end)

	return create "Frame" {

		Name = "Line",

		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = function()
			local middle = middle()
			return UDim2.fromOffset(middle.X, middle.Y)
		end,
		Size = function()
			local distance = point_b() - point_a()
			return UDim2.fromOffset(read(thickness), distance.Magnitude + (read(thickness) :: number) / 2)
		end,
		Rotation = function()
			local distance = point_a() - point_b()
			return -math.deg(math.atan2(distance.X, distance.Y))
		end,

		BackgroundColor3 = props.color,
	}
end

return line
