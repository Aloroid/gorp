# gorp

## Properties

### style

Contains a list of all the colors for gorp.
Modify this before spawning a widget to change the theme

## Functions

### set_ecr()

::: info
TS exclusive
:::

-   **Type**

```ts
function gorp.set_ecr(ecr)
```

-   **Details**

This must be set immediately after gorp is imported on both the client and server.

### add_world()

Adds a world or registry and allows gorp to display it.

-   **Type**

```lua
function gorp.add_world(world: ecr.Registry, name: string?): ()
```

-   **Details**

Worlds cannot be removed once added.

### set_check_if_user_allowed()

Changes the function that checks if a user is allowed to use gorp

-   **Type**

```lua
function gorp.set_check_if_user_allowed(callback: (player: Player) -> boolean): ()
```

-   **Details**

::: warning
If you are changing this, you must change it on both the server and client
:::

By default, you can only open this if you are the game creator or you are in studio.

### spawn_widget()

Spawns a widget in. Normally you'd only have to spawn `registry_selector`.
Returns a function that destroys the widget.

-   **Type**

```lua
function gorp.spawn_widget(widget: "registry_selector"): () -> ()

function gorp.spawn_widget(widget: "entity_client_view", props: {
	query: vide.Source<string>?,
	world: {world: ecr.Registry, name: string},
	cleanup: (() -> ())?,
	get_components: ((id: number) -> {number})
}): () -> ()

function gorp.spawn_widget(widget: "entity_server_view", name: string, registry: number): () -> ()

function gorp.spawn_widget(widget: "json_editor", props: {
	name: string,
	text: string,
	updated: (text: string) -> (),
	prettify: boolean?
}): () -> ()

function gorp.spawn_widget(widget: "scheduler_view", scheduler: gorp.Scheduler): () -> ()

function gorp.spawn_widget(widget: "scheduler_server_view", name: string, scheduler: number): () -> ()

function gorp.spawn_widget(widget: "system_view", scheduler: gorp.Scheduler, system: number): () -> ()

function gorp.spawn_widget(widget: "system_server_view", scheduler: number, index: number, name: string): () -> ()
```

### scale()

The scale of the UI

-   **Type**

```lua
function gorp.scale(scale: number): ()
function gorp.scale(): number
```

-   **Details**

Scale is not supported, and not all UI may properly work with scale.

### clear_all()

Closes all the widgets

-   **Type**

```lua
function gorp.clear_all(): ()
```

### add_custom_json_convert()

Allows you to add a custom function for converting a datatype to JSON

-   **Type**

```lua
function gorp.add_custom_json_convert(datatype: string,
	options: {
		deconstruct: ((value: T) -> U & JSON)?,
		construct: ((value: U) -> T)?,
		construct_array: ((...any) -> T)?,
	}
): ()
```

### enabled()

If the UI is enabled or disabled

-   **Type**

```lua
function gorp.enabled(enabled: boolean): ()
function gorp.enabled(): boolean
```

### compat_set_cts()

Sets the components that gorp knows of

-   **Type**

```lua
function gorp.compat_set_cts<T>(cts: T & {[string]: ctype}): T
```

-   **Details**

gorp automatically replicates all the server components to the client

### scheduler.new()

Creates a new [scheduler](scheduler.md)

-   **Type**

```lua
function gorp.scheduler.new(name: string): Scheduler
```

### pass_config()

Configures and changes some part of gorp.

-   **Type**

```lua
function gorp.pass_config(config: {allow_yielding: boolean}): ()
```

-   **Details**

Current options are:
`allow_yielding: boolean` Allows systems to yield. The time spent yielding is not ignored by the scheduler.

### register_custom_widget()

Registers a custom widget which can be opened with a button in the registry selector

-   **Type**

```lua
function gorp.register_custom_widget(widget: string, type: "server" | "client" | "none", callback: () -> ()): ()
```

-   **Details**

It doesn't create a widget for you.
