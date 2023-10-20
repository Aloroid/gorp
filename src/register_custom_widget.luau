local state = require(script.Parent.state)

local function register_custom_widget(
	widget: string,
	type: "server" | "client" | "none",
	callback: () -> ()
)
	local custom_widgets = state.custom_widgets()

	table.insert(
		custom_widgets,
		{ name = widget, type = type, callback = callback }
	)

	state.custom_widgets(custom_widgets)
end

return register_custom_widget
