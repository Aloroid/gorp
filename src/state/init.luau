local RunService = game:GetService("RunService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local common_actor_id = require(script.Parent.common_actor_id)
local rts = require(script.Parent.rts)
local vide = require(script.Parent.Parent.vide)

local source = vide.source

return vide.root(function()
	local cts = require(script.cts)

	local actors = SharedTableRegistry:GetSharedTable("_actors")
	local all_worlds =
		SharedTableRegistry:GetSharedTable("_gorp_server_worlds_entries")
	local all_schedulers =
		SharedTableRegistry:GetSharedTable("_gorp_server_schedulers_entries")
	local using_actors =
		SharedTableRegistry:GetSharedTable("_gorp_server_actors")

	all_worlds.size = all_worlds.size or 1
	all_schedulers.size = all_schedulers.size or 1
	all_worlds.entries = all_worlds.entries or {}
	all_schedulers.entries = all_schedulers.entries or {}
	actors.size = actors.size or 0

	return {

		scale = source(1),
		widgets = {} :: { () -> () },

		actor_id = common_actor_id,

		actors = actors :: { size: number } & SharedTable,
		all_worlds = all_worlds :: {
			size: number,
			entries: { { name: string, index: number, actor: Actor? } },
		} & SharedTable,
		all_schedulers = all_schedulers :: {
			size: number,
			entries: { { name: string, index: number, actor: Actor? } },
		} & SharedTable,
		using_actors = using_actors :: { Actor } & SharedTable,

		cts = cts,
		worlds = source({} :: {
			{
				world: rts.Registry,
				name: string,
				global_index: number,
			}
		}),
		schedulers = source({} :: { rts.Scheduler }),

		current_client_world = source({} :: { world: rts.Registry, name: string }),
		enabled = source(false),

		custom_widgets = source({} :: {
			{
				name: string,
				type: "server" | "client" | "none",
				callback: () -> (),
			}
		}),

		can_use_debugger = function(player: Player)
			return (
				game.CreatorType == Enum.CreatorType.User
				and player.UserId == game.CreatorId
			) or RunService:IsStudio()
		end,

		iterating_groups = nil :: {
			{
				s: number,
				ent: number,
				includes: { number },
				is_group: true,
			}
		}?,
	}
end)
