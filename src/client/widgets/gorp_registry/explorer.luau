--[[

	registry_explorer

]]

local button = require(script.Parent.Parent.Parent.components.button)
local container = require(script.Parent.Parent.Parent.components.container)
local custom_data = require(script.Parent.Parent.Parent.Parent.modules.custom_data)
local generic_ecs_layer = require(script.Parent.Parent.Parent.Parent.generic_ecs_layer)
local gorp = require(script.Parent.Parent.Parent.Parent.gorp)
local style = require(script.Parent.Parent.Parent.style)
local table_ui = require(script.Parent.Parent.Parent.components.table)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)

type Source<T> = vide.Source<T>

return function(props: {
	parsed_query: Source<gorp.ParsedECSQuery>,
	world: vide.Source<{ vide.Source<{ unknown }> }>,

	on_click_field: ((id: number, ctype: number) -> ())?,
})
	local parsed_query = props.parsed_query
	local world = props.world
	local on_click_field = props.on_click_field

	return table_ui {

		meaning = function()
			local parsed_query = parsed_query()
			local t = if parsed_query.ok == false then { "Id" } else { "Id", unpack(parsed_query.included_names) }
			if #t == 1 then table.insert(t, "") end
			return t
		end,

		base_sizes = { 0.15, 0.85 },
		item_size = 24,

		rows = world,

		display = function(column, row)
			if world()[row()] == nil then return container {} end
			-- gets the ctype
			local function ctype()
				local query = parsed_query()
				return query.ok and query.included[column - 1] or nil
			end

			local function value()
				if world()[row()] == nil then return nil :: any end
				return world()[row()]()[column]
			end

			local radius = style.corner_radius
			local background = style.button
			style.corner_radius = UDim.new()
			style.button = style.background

			local button = button {

				layout = { Size = UDim2.fromScale(1, 1) },
				font = Enum.Font.Code,

				text = function()
					if value() == nil then return "-" end
					if column == 1 then
						return generic_ecs_layer.id(value())
					elseif ctype() then
						local value = value()
						return custom_data.encode(value)
					else
						return "-"
					end
				end,
				text_size = 14,

				activated = function()
					if on_click_field == nil then return end
					on_click_field(value()[1] :: number, ctype())
				end,
			}

			style.corner_radius = radius
			style.button = background

			return button
		end,
	}
end
