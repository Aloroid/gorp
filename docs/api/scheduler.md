# Scheduler

A scheduler can be created using [`gorp.scheduler.new()`](./gorp.md#schedulernew).

::: danger
The scheduler does not currently properly support removing systems.
:::

## Functions

### scheduler:pause()

Pauses a system that is currently running

-   **Type**

```lua
function scheduler:pause(index: number): ()
```

### scheduler:resume()

Resumes a system that is currently paused

-   **Type**

```lua
function scheduler:resume(index: number): ()
```

### scheduler:get_paused()

Returns if a system is currently paused or not

-   **Type**

```lua
function scheduler:get_paused(index: number): boolean
```

### scheduler:get_all_paused()

Returns a list of indexes for systems that are paused.

-   **Type**

```lua
function scheduler:get_all_paused(): {number}
```

### scheduler:get_index()

Gets the index of a system

-   **Type**

```lua
function scheduler:get_index(name: string): number?
```

### scheduler:get_system()

Gets the name of a index

-   **Type**

```lua
function scheduler:get_system(index: number): string
```

### scheduler:system()

Runs the given system with the provided arguments

-   **Type**

```lua
function scheduler:system<T...>(name: string, system: (T...) -> (), ...: T...): ()
```

-   **Details**

The system mustn't yield. Yielding will produce a error. Any errors are reported as a warn.

### scheduler:skip()

Marks a system as skipped

-   **Type**

```lua
function scheduler:skip(name: string): ()
```

### scheduler:finish()

Marks the end of the update loop and starts the next frame in gorp

-   **Type**

```lua
function scheduler:finish(): ()
```

## Example

An example update loop with gorp would look like

```lua
RunService.Heartbeat:Connect(function()

	scheduler:system("update_velocities", update_velocities)
	scheduler:system("reconcile_transform", reconcile_transform)
	scheduler:finish()

end)

```
