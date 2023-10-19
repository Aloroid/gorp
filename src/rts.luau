local ecr = require(script.Parent.Parent.ecr)
local vide = require(script.Parent.Parent.vide)

export type Entity = ecr.Entity
export type Signal<T...> = ecr.Signal<T...>
export type Connection = ecr.Connection
export type Handle = ecr.Handle
export type View<T...> = ecr.View<T...>
export type Observer<T...> = ecr.Observer<T...>
export type Group<T...> = ecr.Group<T...>
export type Registry = ecr.Registry
export type Queue<T...> = ecr.Queue<T...>
export type Source<T> = vide.Source<T>

export type Scheduler = {

	name: string,

	systems: {
		{
			name: string,
			time: {
				add: (any, number) -> (),
				average: (any) -> number,
				values: { number },
			},

			_before: any,
			_after: any,
		}
	},

	before: (Scheduler, given_name: string) -> (),
	after: (Scheduler) -> (),
	finish: (Scheduler) -> (),

	_hook_before_system: (
		Scheduler,
		index: number,
		callback: () -> (),
		cleanup: (() -> ())?
	) -> () -> (),
	_hook_after_system: (
		Scheduler,
		index: number,
		callback: () -> (),
		cleanup: (() -> ())?
	) -> () -> (),
}

return nil
