local remotes = require(script.Parent.Parent.remotes)

local connectors = {

	connected = {} :: { [remotes.connector]: true },
}

return connectors
