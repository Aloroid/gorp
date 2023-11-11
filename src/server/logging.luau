local signal = require(script.Parent.Parent.modules.signal)
local ERROR = error
local WARN = warn
local PRINT = print

local function scope(...: string)
	local scopes = { ... }
	local logs = {}
	local updated, fire = signal()

	local function err_no_kill(...: string)
		local str = table.concat({ ... }, "\t")
		table.insert(logs, { type = "error", msg = str, scope = scopes })
		fire(logs)
		return str
	end

	local function error(...: string) ERROR(err_no_kill(...), 2) end

	local function warn(...: string)
		local str = table.concat({ ... }, "\t")
		table.insert(logs, { type = "warn", msg = str, scope = scopes })
		fire(logs)
		WARN(...)
	end

	local function info(...: string)
		local str = table.concat({ ... }, "\t")
		table.insert(logs, { type = "info", msg = str, scope = scopes })
		PRINT(...)
		fire(logs)
	end

	local function attach(...: string)
		local copy = table.clone(scopes)
		table.move({ ... }, 1, select("#", ...), #copy + 1, copy)

		return scope(unpack(copy))
	end

	return {

		attach = attach,
		error = error,
		warn = warn,
		info = info,

		logs = logs,
		updated = updated,
	}
end

return scope
