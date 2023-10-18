local delta = 0.075

return function(value: number) return Color3.fromHSV(value * delta, 1, 1) end
