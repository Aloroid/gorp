local dynamic_ecs_query = require(script.Parent.modules.dynamic_ecs_query)
local net = require(script.Parent.modules.net)
local signal = require(script.Parent.modules.signal)
local vide = require(script.Parent.Parent.vide)

export type ParsedECSQuery = dynamic_ecs_query.ParsedECSQuery

export type system = number

export type connector = net.connector

export type Source<T> = vide.Source<T>

export type Signal<T...> = signal.SignalInternal<T...>

export type Scheduler = {

	name: string,

	system_paused: { [system]: true },
	system_names: { [system]: string },
	system_order: { system },
	system_data: {
		[system]: {
			index: number,
			average: RollingAverage,
			before: { (name: string) -> () },
			after: { (name: string) -> () },
		},
	},

	updated_order: boolean,

	system: <T...>(Scheduler, name: string, callback: (T...) -> (), T...) -> (),
	skip: (Scheduler, name: string) -> (),
	finish: (Scheduler) -> (),
}

export type RollingAverage = {

	average: (RollingAverage) -> number,
	add: (RollingAverage, value: number) -> (),
	updated: (RollingAverage) -> boolean,

	values: { number },
}

export type System = {

	index: number,

	before: { (name: string) -> () },
	after: { (name: string) -> () },
}

export type QueryData = {

	ctypes: { number },
	is_group: boolean,

	perent_ns: RollingAverage,
	periter_ns: RollingAverage,
}

return nil
