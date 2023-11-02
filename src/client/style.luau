--!nolint LocalUnused

local dark = {

	background = Color3.fromRGB(46, 46, 46),
	foreground = Color3.fromRGB(52, 52, 52),

	input = Color3.fromRGB(40, 40, 40),

	button = Color3.fromRGB(62, 62, 62),
	button_hovering = Color3.fromRGB(70, 70, 70),
	button_pressed = Color3.fromRGB(36, 36, 36),

	tab_background = Color3.fromRGB(46, 46, 46),
	tab_hovering = Color3.fromRGB(80, 80, 80),
	tab_selected = Color3.fromRGB(36, 36, 36),

	border = Color3.fromRGB(36, 36, 36),
	border_selected = Color3.fromRGB(53, 181, 255),

	text = Color3.fromRGB(240, 240, 240),
	sub_text = Color3.fromRGB(170, 170, 170),
	font = Enum.Font.SourceSans,
	font_size = 18,

	scroll_bar = Color3.fromRGB(70, 70, 70),

	padding = UDim.new(0, 8),

	corner_radius = UDim.new(0, 4),

	microprofiler_bar_top = Color3.fromRGB(253, 189, 145),
	microprofiler_bar_bot = Color3.fromRGB(149, 85, 41),
}

local stupid = {

	background = Color3.new(),
	foreground = Color3.fromRGB(10, 10, 10),

	input = Color3.fromRGB(10, 10, 10),

	button = Color3.fromRGB(0, 0, 0),
	button_hovering = Color3.fromRGB(50, 50, 50),
	button_pressed = Color3.fromRGB(10, 10, 10),

	tab_background = Color3.fromRGB(0, 0, 0),
	tab_hovering = Color3.fromRGB(50, 50, 50),
	tab_selected = Color3.fromRGB(20, 20, 20),

	border = Color3.fromRGB(240, 240, 240),
	border_selected = Color3.fromRGB(0, 255, 53),

	text = Color3.fromRGB(0, 255, 109),
	sub_text = Color3.fromRGB(64, 167, 73),
	font = Enum.Font.SourceSans,
	font_size = 18,

	scroll_bar = Color3.fromRGB(38, 90, 33),

	padding = UDim.new(0, 4),

	corner_radius = UDim.new(0, 4),

	microprofiler_bar_top = Color3.fromRGB(253, 189, 145),
	microprofiler_bar_bot = Color3.fromRGB(149, 85, 41),
}

return dark
