local cheapnet = require(script.Parent.modules.cheapnet)
local ecr = require(script.Parent.Parent.ecr)
local signal = require(script.Parent.modules.signal)
local vide = require(script.Parent.Parent.vide)

export type Entity = ecr.Entity
export type Connection = ecr.Connection
export type Handle = ecr.Handle
export type View<T...> = ecr.View<T...>
export type Observer<T...> = ecr.Observer<T...>
export type Group<T...> = ecr.Group<T...>
export type Registry = ecr.Registry
export type Queue<T...> = ecr.Queue<T...>

export type Source<T> = vide.Source<T>

export type Event<T...> = cheapnet.Event<T...>
export type Function<T..., U...> = cheapnet.Function<T..., U...>
export type Signal<T...> = signal.Signal<T...>

return nil
