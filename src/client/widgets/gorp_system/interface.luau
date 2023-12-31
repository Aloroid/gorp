local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)
local tabs = require(script.Parent.Parent.Parent.components.tabs)
local widget = require(script.Parent.Parent.Parent.components.widget)
local performance_tab = require(script.Parent.performance_tab)

local source = vide.source

type props = {

	system_name: string,
	system_times: () -> {number},
	system_labels: {{
		category: string,
		labels: () -> {string}
	}},

	destroy: () -> ()

}

return function(props: props)

	return widget {

		title = `System {props.system_name}`,
		min_size = Vector2.new(250, 400),

		bind_to_close = props.destroy,

		tabs {

			{
				name = "Performance",
				child = function()
					return performance_tab(props)
				end
			}

		}

	}

end