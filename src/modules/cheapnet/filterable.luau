--[[

	filterables allow you to easily filter through players

]]

local Players = game:GetService("Players")

export type Filterable = {

	-- includes the given players from the filterable.
	include: (Filterable, players: Player | { Player }) -> Filterable,
	-- excludes the given players currently added to the filterable
	exclude: (Filterable, players: Player | { Player }) -> Filterable,

	-- adds all the players, equivalent to :include(Players:GetPlayers())
	all: (Filterable) -> Filterable,

	-- :never excludes a player in a filterable.
	-- this will remove the player from the filterable and make sure it can't be added again
	-- calling this on a player that must always remain in will error.
	-- subsequent :include calls will ignore this player
	never: (Filterable, players: Player | { Player }) -> Filterable,
	-- :always includes a player in a filterable
	-- this will add the player to the filterable and make sure it can't be removed.
	-- calling this on a player that must never go in the filter will error.
	-- subsequent :exclude calls will ignore this player
	always: (Filterable, players: Player | { Player }) -> Filterable,

	-- generates a list of players that are included
	list: (Filterable) -> { Player },
	-- returns if the player is included
	has: (Filterable, player: Player) -> boolean,
}

type Internal = {
	players: { [Player]: true },
	never_in: { [Player]: true },
	always_in: { [Player]: true },
} & Filterable

local filterable = {}
filterable.__index = filterable

function filterable.include(self: Internal, players: { Player } | Player)
	if type(players) == "table" then
		for _, player in players do
			if self.never_in[player] then continue end
			self.players[player] = true
		end
	else
		local player = players
		if self.never_in[player] then return self end
		self.players[player] = true
	end

	return self
end

function filterable.exclude(self: Internal, players: { Player } | Player)
	if type(players) == "table" then
		for _, player in players do
			if self.always_in[player] then continue end
			self.players[player] = nil
		end
	else
		local player = players
		if self.always_in[player] then return self end
		self.players[player] = nil
	end

	return self
end

function filterable.all(self: Internal)
	self:include(Players:GetPlayers())
	return self
end

function filterable.always(self: Internal, players: { Player } | Player)
	if type(players) == "table" then
		for _, player in players do
			if self.never_in[player] then
				error(`{player.Name} must never be included`)
			end
			self.always_in[player] = true
		end
	else
		local player = players
		if self.never_in[player] then
			error(`{player.Name} must never be included`)
		end
		self.always_in[player] = true
	end

	self:include(players)

	return self
end

function filterable.never(self: Internal, players: { Player } | Player)
	if type(players) == "table" then
		for _, player in players do
			if self.always_in[player] then
				error(`{player.Name} must always be included`)
			end
			self.never_in[player] = true
		end
	else
		local player = players
		if self.always_in[player] then
			error(`{player.Name} must always be included`)
		end
		self.never_in[player] = true
	end

	self:exclude(players)

	return self
end

function filterable.list(self: Internal)
	local players = {}

	for player in self.players do
		table.insert(players, player)
	end

	return players
end

function filterable.has(self: Internal, player: Player)
	return not not self.players[player]
end

local function new_filterable(): Filterable
	local self = setmetatable({
		players = {} :: { [Player]: true },
		never_in = {} :: { [Player]: true },
		always_in = {} :: { [Player]: true },
	}, filterable)

	return self :: any
end

return new_filterable
