# Scheduler

A scheduler can be created using [`gorp.scheduler.new()`](./gorp.md#schedulernew).

::: danger
The scheduler does not currently properly support removing systems.
:::

## Functions

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
