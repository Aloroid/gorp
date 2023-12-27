local signal = require(script.Parent.Parent.modules.signal)

type signal = signal.SignalInternal

return {

	components_updated = signal() :: signal,

	world_created = signal() :: signal,
	scheduler_created = signal() :: signal,
}
