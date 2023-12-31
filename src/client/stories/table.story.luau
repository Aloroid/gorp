local background = require(script.Parent.Parent.components.background)
local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local layout = require(script.Parent.Parent.components.layout)
local table_display = require(script.Parent.Parent.components.table)
local text = require(script.Parent.Parent.components.text)
local text_input = require(script.Parent.Parent.components.text_input)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local source = vide.source
local effect = vide.effect
local untrack = vide.untrack

return function(target: ScreenGui)
	local destroy = vide.root(function(destroy)
		local t = source({})

		for i = 1, 10000 do
			table.insert(t(), source({ i, Vector3.new(0, i, 0), 100 } :: { any }))
		end

		background {
			Parent = target,

			button {
				text = "--print table",

				activated = function()
					for _, row in t() do
						local clone = {}
						for _, value in row() do
							table.insert(clone, tostring(value))
						end
						--print(table.concat(clone, ", "))
					end
				end,
			},

			layout {},

			table_display {

				meaning = source({ "Id", "Position", "Health" }),
				rows = t,

				display = function(value: () -> any, column, row)
					if column == 2 then
						local x, y, z =
							source(tostring(value().X)), source(tostring(value().Y)), source(tostring(value().Z))

						local function update_vector(text: string, enter: boolean)
							if tonumber(text) == nil or enter == false then
								x(tostring(value().X))
								y(tostring(value().Y))
								z(tostring(value().Z))
								return
							end

							local row = t()[row()]
							local clone = table.clone(row())
							clone[column] = Vector3.new(tonumber(x()), tonumber(y()), tonumber(z()))
							row(clone)
						end

						effect(function()
							row()

							local value = untrack(value)
							x(tostring(value.X))
							y(tostring(value.Y))
							z(tostring(value.Z))
						end)

						return container {
							layout {
								FillDirection = Enum.FillDirection.Horizontal,
							},

							text_input {
								layout = {
									Size = UDim2.new(1 / 3, -6, 1, 0),
								},

								text = x,
								focus_lost = update_vector,
							},

							text_input {
								layout = {
									Size = UDim2.new(1 / 3, -6, 1, 0),
								},
								text = y,
								focus_lost = update_vector,
							},

							text_input {
								layout = {
									Size = UDim2.new(1 / 3, -6, 1, 0),
								},
								text = z,
								focus_lost = update_vector,
							},
						}
					elseif column == 3 then
						local text = source(tostring(value()))

						effect(function()
							row()

							local value = untrack(value)
							text(tostring(value))
						end)

						return text_input {
							layout = {
								Size = UDim2.fromScale(1, 1),
							},

							text = text,
							focus_lost = function(current_text, enter)
								if enter == false then
									text(value())
									return
								end

								local row = t()[row()]
								local clone = table.clone(row())
								clone[column] = current_text
								row(clone)
							end,
						}
					end

					return text {
						layout = { Size = UDim2.fromScale(1, 1) },

						text = value,
					}
				end,

				item_size = 32,
			},
		}

		return destroy
	end)

	return function() destroy() end
end
