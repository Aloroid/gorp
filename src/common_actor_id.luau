--[[

	common_actor_id gives each luau vm it's own id.

]]

local SharedTableRegistry = game:GetService("SharedTableRegistry")

local shared_table = SharedTableRegistry:GetSharedTable("_gorp_common_actor_id")
shared_table.id = shared_table.id or 1 -- count from 1

return SharedTable.increment(shared_table, "id", 1)
