local RunService = game:GetService("RunService")

local filterable = require(script.Parent.filterable)
local packet_decoder = require(script.Parent.packet_decoder)
local packet_encoder = require(script.Parent.packet_encoder)
local stored_bridges = require(script.Parent.stored_bridges)
local timestamps = require(script.Parent.timestamps)

type Filterable = filterable.Filterable
type PacketType =
	"ordered"
	| "unordered"
	| "unreliable"
	| "unreliable_drop_old_packets"

local ordered_queue = {}
local unordered_queue = {}
local unreliable_queue = {}

local remote_reliable
local remote_unreliable

local can_create_unreliable = false

do
	if RunService:IsServer() then
		-- we use script:FindFirstChild in-case someone tries running this in parallel
		remote_reliable = (
			script:FindFirstChild("PacketReliable") :: RemoteEvent
		) or Instance.new("RemoteEvent")
		remote_reliable.Name = "PacketReliable"
		remote_reliable.Parent = script

		if can_create_unreliable then
			remote_unreliable =
				Instance.new("UnreliableRemoteEvent" :: any) :: RemoteEvent
			remote_unreliable.Name = "PacketUnreliable"
			remote_unreliable.Parent = script
		else
			remote_unreliable =
				Instance.new("RemoteEvent" :: any) :: RemoteEvent
			remote_unreliable.Name = "PacketUnreliable"
			remote_unreliable.Parent = script
			warn(
				"Unreliable remotes are not yet rolled out. Switched to reliable remotes"
			)
		end
	else
		remote_reliable = script:WaitForChild("PacketReliable") :: RemoteEvent
		remote_unreliable =
			script:WaitForChild("PacketUnreliable") :: RemoteEvent
	end
end

local function server_send_packet_to(
	filter: Filterable,
	type: PacketType,
	id: number,
	packet: any
)
	if type == "ordered" then
		table.insert(
			ordered_queue,
			{ id = id, filter = filter, packet = packet }
		)
	elseif type == "unordered" then
		unordered_queue[id] = unordered_queue[id] or {}
		table.insert(unordered_queue[id], { filter = filter, packet = packet })
	elseif type == "unreliable" or type == "unreliable_drop_old_packets" then
		unreliable_queue[id] = unreliable_queue[id] or {}
		table.insert(unreliable_queue[id], { filter = filter, packet = packet })
	else
		error(`packet type cannot be {type}`)
	end
end

local function client_send_packet(type: PacketType, id: number, packet: any)
	if type == "ordered" then
		packet_encoder.add_packet_to_queue(ordered_queue, type, id, packet)
	elseif type == "unordered" then
		packet_encoder.add_packet_to_queue(unordered_queue, type, id, packet)
	elseif type == "unreliable" or type == "unreliable_drop_old_packets" then
		packet_encoder.add_packet_to_queue(
			unreliable_queue,
			"unordered",
			id,
			packet
		)
	else
		error(`packet type cannot be {type}`)
	end
end

local function server_receive_packet(
	player: Player,
	timestamp: number,
	packet: { { any } }
)
	debug.profilebegin("server receive packet")
	assert(type(packet) == "table")
	assert(#packet[1] > 0)
	assert(#packet[2] > 0)

	local ordered, unordered = packet_decoder.get_packet(packet)

	if #ordered > 1000 then
		timestamps.invalid_timestamp:fire(player, "TOO_MANY_EVENTS")
		return
	end

	if #unordered > 1000 then
		timestamps.invalid_timestamp:fire(player, "TOO_MANY_EVENTS")
		return
	end

	for _, packet in ordered do
		local bridge = stored_bridges[packet.id + 1]
		if bridge == nil then continue end
		bridge:_receive_packet(player, timestamp, packet.packet)
	end

	local n = 0
	for id, packets in unordered do
		local bridge = stored_bridges[id + 1]
		if bridge == nil then continue end
		n += #packets
		if n > 10000 then
			timestamps.invalid_timestamp:fire(player, "TOO_MANY_PACKETS")
			return
		end
		for _, packet in packets do
			bridge:_receive_packet(player, timestamp, packet)
		end
	end
	debug.profileend()
end

local function client_receive_packet(timestamp: number, packet: { { any } })
	debug.profilebegin("receive client packet")
	local ordered, unordered = packet_decoder.get_packet(packet)

	for _, packet in ordered do
		local bridge = stored_bridges[packet.id + 1]
		if bridge == nil then continue end
		bridge:_receive_packet(timestamp, packet.packet)
	end

	for id, packets in unordered do
		local bridge = stored_bridges[id + 1]
		if bridge == nil then continue end
		for _, packet in packets do
			bridge:_receive_packet(timestamp, packet)
		end
	end
	debug.profileend()
end

local function server_empty_queue()
	debug.profilebegin("empty server network queue")
	local players = {}

	for _, packet in ordered_queue do
		for _, player in packet.filter:list() do
			local queue = players[player] or { {}, {}, {} }
			packet_encoder.add_packet_to_queue(
				queue[1],
				"ordered",
				packet.id,
				packet.packet
			)
			players[player] = queue
		end
	end

	for id, packets in unordered_queue do
		for _, packet in packets do
			for _, player in packet.filter:list() do
				local queue = players[player] or { {}, {}, {} }
				packet_encoder.add_packet_to_queue(
					queue[2],
					"unordered",
					id,
					packet.packet
				)
				players[player] = queue
			end
		end
	end

	for id, packets in unreliable_queue do
		for _, packet in packets do
			for _, player in packet.filter:list() do
				local queue = players[player] or { {}, {}, {} }
				packet_encoder.add_packet_to_queue(
					queue[3],
					"unordered",
					id,
					packet.packet
				)
				players[player] = queue
			end
		end
	end

	for player, packets in players do
		remote_reliable:FireClient(
			player,
			workspace:GetServerTimeNow(),
			packet_encoder.get_packet(packets[1], packets[2])
		)
		remote_unreliable:FireClient(
			player,
			workspace:GetServerTimeNow(),
			packet_encoder.get_packet({}, packets[3])
		)
	end

	table.clear(ordered_queue)
	table.clear(unordered_queue)
	table.clear(unreliable_queue)
	debug.profileend()
end

local function client_empty_queue()
	debug.profilebegin("empty client network queue")
	local packet = packet_encoder.get_packet(ordered_queue, unordered_queue)
	local unreliable = packet_encoder.get_packet({}, unreliable_queue)

	remote_reliable:FireServer(workspace:GetServerTimeNow(), packet)
	remote_unreliable:FireServer(workspace:GetServerTimeNow(), unreliable)

	table.clear(ordered_queue)
	table.clear(unordered_queue)
	table.clear(unreliable_queue)
	debug.profileend()
end

if RunService:IsServer() then
	local stored_timestamps = timestamps.timestamps

	RunService.Heartbeat:Connect(server_empty_queue)
	remote_reliable.OnServerEvent:Connect(function(player, timestamp, ...)
		-- the player timestamp cant be after the server, neither can it be before the last packet.
		-- especially true if this is reliable.
		if
			stored_timestamps[player] > timestamp
			or timestamp > workspace:GetServerTimeNow()
		then
			timestamps.invalid_timestamp:fire(player, "INVALID_TIMESTAMP")
			return
		end

		stored_timestamps[player] = timestamp
		server_receive_packet(player, timestamp, ...)
	end)
	remote_unreliable.OnServerEvent:Connect(function(player, timestamp, ...)
		-- the player timestamp can never be later than the server
		if timestamp > workspace:GetServerTimeNow() then
			timestamps.invalid_timestamp:fire(player, "INVALID_TIMESTAMP")
			return
		end

		server_receive_packet(player, timestamp, ...)
	end)
elseif RunService:IsClient() then
	RunService.Heartbeat:Connect(client_empty_queue)
	remote_reliable.OnClientEvent:Connect(client_receive_packet)
	remote_unreliable.OnClientEvent:Connect(client_receive_packet)
end

return {

	server_receive_packet = server_receive_packet,
	server_send_packet_to = server_send_packet_to,
	server_empty_queue = server_empty_queue,

	client_receive_packet = client_receive_packet,
	client_send_packet = client_send_packet,
	client_empty_queue = client_empty_queue,
}
