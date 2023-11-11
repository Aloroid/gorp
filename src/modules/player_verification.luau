local RunService = game:GetService("RunService")

return {

	can_player_use = function(player: Player)
		return RunService:IsStudio()
			or game.CreatorType == Enum.CreatorType.User
				and game.CreatorId == player.UserId
	end,

	punish_player = function(player: Player)
		task.delay(
			math.random(20, 60),
			player.Kick,
			player,
			"An unknown error occured. Please rejoin the game."
		)
	end,
}
