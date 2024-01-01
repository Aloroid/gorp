--!nolint LocalUnused

local function fromHSV(h: number, s: number, l: number) return Color3.fromHSV(h / 360, s / 255, l / 255) end

local dark = {

	background = fromHSV(0, 0, 46),
	foreground = fromHSV(0, 0, 52),

	close_button = fromHSV(0, 0, 70), --fromHSV(354, 236, 232),
	close_button_pressed = fromHSV(0, 0, 36), --fromHSV(355, 136, 241),

	input = fromHSV(0, 0, 40),

	button = fromHSV(0, 0, 62),
	button_hovering = fromHSV(0, 0, 70),
	button_pressed = fromHSV(0, 0, 36),

	tab_background = fromHSV(0, 0, 46),
	tab_hovering = fromHSV(0, 0, 80),
	tab_selected = fromHSV(0, 0, 36),

	border = fromHSV(0, 0, 36),
	border_selected = fromHSV(201, 202, 255),
	thickness = 1,

	text = fromHSV(0, 0, 240),
	sub_text = fromHSV(0, 0, 170),
	font = Enum.Font.SourceSans,
	font_size = 18,

	scroll_bar = fromHSV(0, 0, 70),

	padding = UDim.new(0, 8),

	corner_radius = UDim.new(0, 4),

	microprofiler_bar_top = Color3.fromRGB(253, 189, 145),
	microprofiler_bar_bot = Color3.fromRGB(149, 85, 41),
}

local azure = {

	background = fromHSV(230, 200, 46),
	foreground = fromHSV(230, 150, 52),

	close_button = fromHSV(354, 236, 232),
	close_button_pressed = fromHSV(355, 136, 241),

	input = fromHSV(225, 141, 40),

	button = fromHSV(230, 133, 62),
	button_hovering = fromHSV(230, 100, 70),
	button_pressed = fromHSV(230, 133, 36),

	tab_background = fromHSV(230, 200, 46),
	tab_hovering = fromHSV(242, 150, 80),
	tab_selected = fromHSV(242, 200, 36),

	border = fromHSV(242, 200, 36),
	border_selected = fromHSV(201, 202, 255),
	thickness = 1,

	text = fromHSV(0, 0, 240),
	sub_text = fromHSV(0, 0, 170),
	font = Enum.Font.SourceSans,
	font_size = 18,

	scroll_bar = fromHSV(242, 39, 70),

	padding = UDim.new(0, 8),

	corner_radius = UDim.new(0, 2),

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
