--[[

	registry_explorer

]]

local RunService = game:GetService("RunService")

local actions = require(script.Parent.Parent.Parent.actions)
local button = require(script.Parent.Parent.Parent.components.button)
local container = require(script.Parent.Parent.Parent.components.container)
local dynamic_ecs_query = require(script.Parent.Parent.Parent.Parent.modules.dynamic_ecs_query)
local ecr = require(script.Parent.Parent.Parent.Parent.Parent.ecr)
local rbxjson = require(script.Parent.Parent.Parent.Parent.modules.rbxjson)
local rts = require(script.Parent.Parent.Parent.Parent.rts)
local style = require(script.Parent.Parent.Parent.style)
local table_ui = require(script.Parent.Parent.Parent.components.table)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)

local source = vide.source
local derive = vide.derive

type Source<T> = vide.Source<T>

return function(props: {
	parsed_query: Source<rts.ParsedECSQuery>,
	registry: rts.Registry,

	on_click_field: ((id: number, ctype: number) -> ())?,
})
	local parsed_query = props.parsed_query
	local registry = props.registry
	local on_click_field = props.on_click_field

	local query = derive(function()
		print(parsed_query())
		return dynamic_ecs_query.convert_ecs_query(parsed_query(), registry)
	end)

	local ids = source({})

	local function update_client_view()
		debug.profilebegin("update registry query")

		dynamic_ecs_query.invalidate_query(query())
		ids(dynamic_ecs_query.resolve_query(query(), true))
		--print(#ids(), #registry:view(ecr7.entity))

		debug.profileend()
	end

	return table_ui {

		meaning = function()
			local parsed_query = parsed_query()
			local t = if parsed_query.ok == false then { "Id" } else { "Id", unpack(parsed_query.included_names) }
			if #t == 1 then table.insert(t, "") end
			return t
		end,

		base_sizes = { 0.15, 0.85 },
		item_size = 24,

		max_rows = function() return #ids() end,

		display = function(_, column, row)
			local id = function() return ids()[row()] end

			-- if the id is nil then we return a empty container.
			if id() == nil then return container {} end

			-- gets the ctype
			local function ctype()
				local query = parsed_query()
				return query.ok and query.included_no_tags[column - 1] or nil
			end

			local radius = style.corner_radius
			local background = style.button
			style.corner_radius = UDim.new()
			style.button = style.background

			local button = button {

				layout = { Size = UDim2.fromScale(1, 1) },

				text = function()
					if id() == nil then return "-" end

					if column == 1 then
						local key, ver = ecr.inspect(id())
						return `{key}:{ver}`
					elseif ctype() then
						local value = registry:try_get(id(), ctype())
						return if type(value) == "table"
							then rbxjson:Encode(value):gsub("§(.-)§", "")
							else tostring(value)
					else
						return "-"
					end
				end,

				activated = function()
					if on_click_field == nil then return end
					on_click_field(id(), ctype())
				end,
			}

			style.corner_radius = radius
			style.button = background

			return button
		end,

		layout = {
			-- binds cleanup to the instance instead of the scope
			actions.cleanup(RunService.Heartbeat:Connect(update_client_view)),
		},
	}
end
