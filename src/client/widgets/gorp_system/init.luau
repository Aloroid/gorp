local vide = require(script.Parent.Parent.Parent.Parent.vide)
local generic_ecs_layer = require(script.Parent.Parent.Parent.generic_ecs_layer)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local remotes = require(script.Parent.Parent.Parent.remotes)
local servers = require(script.Parent.Parent.servers)
local interface = require(script.interface)

local source = vide.source
local derive = vide.derive
local cleanup = vide.cleanup

local MAX_SYSTEM_PACKETS = 50

type props = {

	system_name: string,
	scheduler_id: number,
	
	connector: remotes.connector

}

local function main(destroy, props: props)
	local connector = props.connector
	local scheduler_id = props.scheduler_id
	local system_name = props.system_name

	local server = servers[connector.namespace][connector.to :: number]

	local system_packets = source({} :: {{runtime: number, labels: {any}, frame: number}})
	local system_labels = {} :: {
		{category: string, labels: () -> {string}}
	}
	local system_times = derive(function()
		local t = {0}
		for i, packet in system_packets() do
			t[i] = packet.runtime
		end
		return t
	end)
	
	for i, label in generic_ecs_layer.system_labels do
		local decode = label.decode
		system_labels[i] = {
			category = label.category,
			
			labels = derive(function()
				local latest_packet = system_packets()[1]
				if latest_packet == nil then return {} end
				return decode(latest_packet.labels[i], server.ctypes)
			end)
		}
	end

	local subscription_id = -1
	local id_received = false

	-- subscribe to the scheduler
	task.spawn(function()
		subscription_id = remotes.subscribe_system:invoke(connector, scheduler_id, system_name)
		id_received = true
	end)

	-- on cleanup, unsubscribe from the system
	cleanup(function()
		while not id_received do
			task.wait()
		end

		remotes.unsubscribe_system:fire(connector, subscription_id)
	end)

	local allow_overflow = false
	local last_packet = 0
	-- create a connection that will run whenever the system receives new timings
	local function on_packet_receive(incoming: remotes.connector, packet: buffer, labels: {{any}})

		incoming = reverse_connector(incoming)

		if incoming.to ~= props.connector.to then return end
		if incoming.namespace ~= props.connector.namespace then return end

		local incoming_sub_id = buffer.readu32(packet, 0)
		if incoming_sub_id ~= subscription_id then return end
		local system_frame = buffer.readu16(packet, 4)
		local runtime = buffer.readf32(packet, 6)
		
		-- if the packet is new but we recently overflowed then we consider the
		-- packet to be early.
		if system_frame > 2^15 * 1.5 and allow_overflow == false then
			system_frame -= 2^16 - 1
		end

		-- make sure the packet isn't stale
		if system_frame > last_packet then
			last_packet = system_frame
			allow_overflow = system_frame > 2^15
		elseif allow_overflow and system_frame < 2^15 then
			last_packet = system_frame
			allow_overflow = false
		else
			return
		end

		local packet = {
			runtime = runtime,
			labels = labels,
			frame = system_frame
		}

		table.remove(system_packets(), MAX_SYSTEM_PACKETS)
		table.insert(system_packets(), 1, packet)
		table.sort(system_packets(), function(a, b)
			return a.frame > b.frame
		end)

		system_packets(system_packets())
	end

	cleanup(remotes.replicate_system_times:connect(on_packet_receive))

	return cleanup(interface {

		system_name = system_name,
		system_times = system_times,
		system_labels = system_labels,

		destroy = destroy

	})

end

return function(props: props)
	vide.root(function(destroy)
		main(destroy, props)
	end)
end