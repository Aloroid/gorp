local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ecr = require(ReplicatedStorage.Packages.ecr)
local gorp = require(ReplicatedStorage.Packages.gorp)

local A, B, C, D = ecr.component(), ecr.component(), ecr.component(), ecr.component()

gorp.names(ecr.name({ A = A, B = B, C = C, D = D }))

local world = ecr.registry()

local id = gorp.hook_world(world, "world")

local client = gorp.get_client()
client.gorp_selector()

local ent = world:create()
world:set(ent, A, true)
