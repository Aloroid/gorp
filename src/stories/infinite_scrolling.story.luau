local vide = require(script.Parent.Parent.Parent.vide)

local scroller = require(script.Parent.Parent.components.scroller)

return function(target: ScreenGui)
	local destroy = vide.mount(function()
		return scroller({

			max_items = vide.source(2000),
			item_size = 24,

			child = function(index)
				return vide.create "TextLabel" {

					Size = UDim2.fromScale(1, 1),

					Text = function() return `I'm {index()}!` end,
					TextSize = 14,
					Font = Enum.Font.SourceSans,
				}
			end,
		})
	end, target)

	return function() destroy() end
end
