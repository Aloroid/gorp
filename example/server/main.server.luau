local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ecr = require(ReplicatedStorage.Packages.ecr)
local gorp = require(ReplicatedStorage.Packages.gorp)

local world = ecr.registry()

gorp.add_world(world, "world")
