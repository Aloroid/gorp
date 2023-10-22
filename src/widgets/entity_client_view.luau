--[[

	Displays a widget containing all the entities on the client.

]]

local RunService = game:GetService("RunService")

local ecr = require(script.Parent.Parent.Parent.ecr)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local dynamic_ecs_query = require(script.Parent.Parent.dynamic_ecs_query)

local background = require(script.Parent.Parent.components.background)
local button = require(script.Parent.Parent.components.button)
local json_editor = require(script.Parent.json_editor)
local layout = require(script.Parent.Parent.components.layout)
local rbxjson = require(script.Parent.Parent.rbxjson)
local rts = require(script.Parent.Parent.rts)
local state = require(script.Parent.Parent.state)
local table_ui = require(script.Parent.Parent.components.table)
local text = require(script.Parent.Parent.components.text)
local text_input = require(script.Parent.Parent.components.text_input)
local widget = require(script.Parent.Parent.components.widget)

local source = vide.source
local effect = vide.effect
local derive = vide.derive

return function(input: {
	query: vide.Source<string>?,
	world: { world: rts.Registry, name: string }?,
	cleanup: (() -> ())?,

	_ignore_heuristic: boolean,
	get_components: ((id: number) -> { number })?,
}?)
	local props = input or {} :: never
	local entry = props.world or state.current_client_world()
	local world = entry.world
	local get_components = props.get_components
		or function(id: number)
			local result = {}
			for ctype, name in state.cts.ids() do
				result[ctype] = world:try_get(id, ctype)
			end
			return result
		end :: never

	local raw_text = source("")
	local unparsed_query = props.query or source("") :: never
	local parsed_query = derive(
		function() return dynamic_ecs_query.parse_ecs_query(unparsed_query()) end
	)
	local ids = source({})
	local query =
		source(dynamic_ecs_query.convert_ecs_query(parsed_query(), world))

	effect(function()
		if parsed_query().ok == false then return end
		query(dynamic_ecs_query.convert_ecs_query(parsed_query(), world))
	end)

	local connection = RunService.Heartbeat:Connect(function(dt)
		debug.profilebegin("updating client view")
		-- invalidates the old query, requiring it to update again
		dynamic_ecs_query.invalidate_query(query())
		ids(dynamic_ecs_query.resolve_query(query(), props._ignore_heuristic))
		debug.profileend()
	end)

	return widget {

		title = `Registry Explorer: {entry.name}`,
		min_size = Vector2.new(250, 400),
		closeable = true,

		background {

			Size = UDim2.fromScale(1, 1),

			layout {},

			text_input {

				text = raw_text,

				focus_lost = function() unparsed_query(raw_text()) end,
			},

			text {
				text = function()
					local result = dynamic_ecs_query.parse_ecs_query(raw_text())
					return if result.ok == false
						then result.err
						else `Displaying {#ids()} entities out of {#world:view(
							ecr.entity
						)}`
				end,

				layout = { TextColor3 = style.sub_text },
			},

			table_ui {

				layout = {
					Size = UDim2.new(1, 0, 1, -(16 + 32 + 8 * 3)),
				},

				meaning = function()
					local result = parsed_query()
					local t = if result.ok == true
						then { "Id", unpack(result.included_names) }
						else { "Id" }
					if #t == 1 then table.insert(t, "") end
					return t
				end,

				max_rows = function() return #ids() end,

				item_size = 24,

				display = function(_, column, row)
					local id = function() return ids()[row()] or ecr.null end
					local ctype = function()
						local query = parsed_query()
						return query.ok and query.included_no_tags[column - 1]
							or nil
					end

					local radius = style.corner_radius
					local background = style.button
					style.corner_radius = UDim.new()
					style.button = style.background

					local button = button {
						layout = {
							Size = UDim2.fromScale(1, 1),
						},

						alignment = Enum.TextXAlignment.Left,

						text = function()
							local key, ver = ecr.extract(id())

							if id() == ecr.null then
								return ""
							elseif column == 1 then
								return `{key}:{ver}`
							elseif ctype() then
								local value = world:try_get(id(), ctype())
								if typeof(value) == "table" then
									return rbxjson
										:Encode(value)
										:gsub("§(.-)§", "")
								else
									return rbxjson
										:Encode(tostring(value))
										:gsub('"', "")
								end
							end

							return ""
						end,

						activated = function()
							--TODO: Allow for editing all the components when clicking the Id
							if column == 1 then
								local id = id()
								local key, ver = ecr.extract(id)
								local components = get_components(id)
								local named = {}
								local cts_ids = state.cts.ids()
								local cts_names = state.cts.keys()

								for ctype, value in components do
									named[cts_ids[ctype]] = value
								end

								return vide.mount(function()
									return json_editor {
										name = `{key}:{ver}`,
										prettify = true,
										text = rbxjson:Encode(named),
										updated = function(new_value)
											local result = rbxjson:Decode(
												new_value,
												"table"
											)

											for name, value in result do
												local ctype = cts_names[name]
												print("set", id, name, value)
												world:set(id, ctype, value)
											end
										end,
									}
								end)
							end
							if ctype() == nil then return end

							local id, ctype = id(), ctype()
							local key, ver = ecr.extract(id)
							local value = world:try_get(id, ctype)

							return vide.mount(function()
								return json_editor {
									name = `{key}:{ver} {unparsed_query()}`,
									prettify = typeof(value) == "table",
									text = rbxjson:Encode(value),
									updated = function(new_value)
										world:set(
											id,
											ctype,
											rbxjson:Decode(
												new_value,
												typeof(value)
											)
										)
									end,
								}
							end)
						end,
					}
					style.corner_radius = radius
					style.button = background

					return button
				end,
			},

			Destroying = function()
				connection:Disconnect()
				if props.cleanup then props.cleanup() end
			end,
		},
	}
end
