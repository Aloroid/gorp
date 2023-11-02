return function(input: string)
	local self = {}
	local column = 0
	local token_begin = 0

	function self:peek() return string.sub(input, column, column) end

	function self:next()
		column += 1
		return string.sub(input, column, column)
	end

	function self:last() return string.sub(input, column - 1, column - 1) end

	function self:eof() return column > #input end

	function self:token(n: number?)
		return string.sub(input, token_begin, column - (n or 0))
	end

	function self:next_token(n: number?)
		local token = self:token(n)
		token_begin = column + 1
		return token
	end

	return self
end
