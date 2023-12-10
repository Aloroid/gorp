local dynamic_ecs_query = require(script.Parent.modules.dynamic_ecs_query)
local ecr = require(script.Parent.Parent.ecr)
local net = require(script.Parent.modules.net)
local signal = require(script.Parent.modules.signal)
local vide = require(script.Parent.Parent.vide)

export type DynamicQuery = dynamic_ecs_query.DynamicQuery
export type ParsedECSQuery = dynamic_ecs_query.ParsedECSQuery

export type entity = ecr.entity
export type Connection = ecr.Connection
export type Handle = ecr.Handle
export type View<T...> = ecr.View<T...>
export type Observer<T...> = ecr.Observer<T...>
export type Group<T...> = ecr.Group<T...>
export type Registry = ecr.Registry
export type Queue<T...> = ecr.Queue<T...>

export type connector = net.connector

export type Source<T> = vide.Source<T>

export type Signal<T...> = signal.SignalInternal<T...>

export type Scheduler = {

	system: <T...>(Scheduler, name: string, callback: (T...) -> (), T...) -> (),
	finish: (Scheduler) -> (),
}

export type RollingAverage = {

	average: (RollingAverage) -> number,
	add: (RollingAverage, value: number) -> (),

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
