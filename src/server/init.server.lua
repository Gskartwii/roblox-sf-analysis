game.Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("Animate"):Destroy()
		local a = script.MixedAnimations:Clone()
		a.Parent = char
	end)
end)
