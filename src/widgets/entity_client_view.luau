--[[

	Displays a widget containing all the entities on the client.

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ecr = require(script.Parent.Parent.Parent.ecr)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)
local widget = require(ReplicatedStorage.Packages.gorp.components.widget)

local dynamic_ecs_query = require(script.Parent.Parent.dynamic_ecs_query)

local background = require(script.Parent.Parent.components.background)
local layout = require(script.Parent.Parent.components.layout)
local state = require(script.Parent.Parent.state)
local table_ui = require(script.Parent.Parent.components.table)
local text = require(script.Parent.Parent.components.text)
local text_input = require(script.Parent.Parent.components.text_input)

local source = vide.source
local effect = vide.effect

return function()
	local entry = state.current_client_world()
	local world = entry.world

	local raw_text = source("")
	local unparsed_query = source("")
	local parsed_query = function()
		return dynamic_ecs_query.parse_ecs_query(unparsed_query())
	end
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
		ids(dynamic_ecs_query.resolve_query(query()))
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
					return text {
						layout = { Size = UDim2.fromScale(1, 1) },

						text = function()
							local id = ids()[row()] or ecr.null
							local result = parsed_query()

							local key, ver = ecr.extract(id)
							local ctype = result.ok
									and result.included_no_tags[column - 1]
								or nil

							return if id == ecr.null
								then ""
								elseif column == 1 then `{key}:{ver}`
								elseif ctype then tostring(
									world:try_get(id, ctype)
								)
								else ""
						end,
					}
				end,
			},

			Destroying = function() connection:Disconnect() end,
		},
	}
end
