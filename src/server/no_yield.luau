--!nocheck
--[[

	nocheck is used here because typechecker likes to complain :P

	Allows for running code in a manner that prevents it to yield.

]]

local is_running = false

local function run()
	-- yield the coroutine so that we can receive our first callback
	local data = { coroutine.yield() }
	while true do
		-- mark as is_running, that way we only have to check if it ran.
		is_running = true
		local values = { data[1](unpack(data, 2)) }
		is_running = false
		data = { coroutine.yield(unpack(values)) }
	end
end

local thread

local function generate_thread()
	is_running = false
	thread = coroutine.create(run)
	coroutine.resume(thread)
end

local function result_handler<T...>(ok: boolean, ...: T...): (boolean, thread, string?)
	if ok == false then
		local thread = thread
		local err = ...

		-- generates a new thread because the current thread is dead
		generate_thread()

		if type(err) == "string" then
			return ok, thread, err
		else
			-- hope roblox does something with it
			return ok, thread, tostring(err)
		end
	elseif is_running == true then
		local thread = thread
		generate_thread()
		coroutine.close(thread)
		return ok, thread, "attempted to yield inside the scheduler"
	end

	return true, thread
end

local function no_yield<T...>(callback: (T...) -> (), ...: T...): (boolean, thread, string?)
	assert(is_running == false, "cannot call no_yield inside no_yield")
	if coroutine.status(thread) == "dead" then generate_thread() end
	print("omfg")
	return result_handler(coroutine.resume(thread, callback, ...))
end

generate_thread()

return no_yield
