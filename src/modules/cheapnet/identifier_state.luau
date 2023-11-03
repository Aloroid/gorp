export type Namespace = {
	size: number,
	keys: { [any]: number },
	values: { [number]: any },
	yielding: { [any]: { thread } },
}

return {} :: { [string]: Namespace }
