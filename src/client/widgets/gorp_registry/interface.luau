--[[

	registry_explorer

]]

local actions = require(script.Parent.Parent.Parent.actions)
local background = require(script.Parent.Parent.Parent.components.background)
local container = require(script.Parent.Parent.Parent.components.container)
local dynamic_ecs_query = require(script.Parent.Parent.Parent.Parent.modules.dynamic_ecs_query)
local explorer = require(script.Parent.explorer)
local layout = require(script.Parent.Parent.Parent.components.layout)
local style = require(script.Parent.Parent.Parent.style)
local text = require(script.Parent.Parent.Parent.components.text)
local text_input = require(script.Parent.Parent.Parent.components.text_input)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)
local widget = require(script.Parent.Parent.Parent.components.widget)

local source = vide.source
local derive = vide.derive
local cleanup = vide.cleanup

type Source<T> = vide.Source<T>

return function(props: {
	query: Source<string>,
	set_query: (new_query: string) -> string,
	on_click_field: (id: number, ctype: number) -> (),

	cts: { [string]: any },

	world: () -> { () -> { unknown } },
	registry_name: string?,

	on_cleanup: (() -> ())?,
})
	return vide.root(function(destroy)
		local raw_text = source("")

		local unparsed_query = props.query
		local set_query = props.set_query
		local parsed_query = derive(function()
			return dynamic_ecs_query(unparsed_query(), props.cts)
		end)

		cleanup(widget {

			title = `Registry Explorer: {props.registry_name}`,
			min_size = Vector2.new(250, 400),

			bind_to_close = destroy,

			background {
				Size = UDim2.fromScale(1, 1),

				layout {},

				text_input {

					text = raw_text,
					placeholder_text = "include: @[ctype] exclude: ![ctype] condition: [ctype]=Vector3(0,0,0)",
					focus_lost = function()
						set_query(raw_text())
					end,
				},

				text {
					text = function()
						local result = dynamic_ecs_query(raw_text(), props.cts)
						print(result, props.cts)
						return if result.ok == false then result.err else ""
					end,

					layout = { TextColor3 = style.sub_text },
				},

				container {
					Size = UDim2.new(1, 0, 1, -(16 + 32 + 8 * 3)),

					explorer {

						on_click_field = props.on_click_field,
						parsed_query = parsed_query,

						world = props.world,
					},
				},
			},

			if props.on_cleanup then actions.cleanup(props.on_cleanup) else nil,
		})
	end)
end
