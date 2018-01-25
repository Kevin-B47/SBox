
if sugar_boom.DarkRP and sugar_boom.Lockpick then
	hook.Add("canLockpick","sugar_boom_lockpick",function(ply,ent,trace)
		if ent:GetClass() == "sugar_boom" then return true end
	end)

	hook.Add("lockpickTime","sugar_boom_lockpickspeed",function(ply,ent)
		if ent:GetClass() == "sugar_boom" then return (sugar_boom.LockpickTime or 15) end
	end)
end

if sugar_boom.DarkRP and sugar_boom.AutoCreateEntity then
	hook.Add("loadCustomDarkRPItems","sugar_boom_load",function()
		DarkRP.createEntity("Boombox", {
			ent = "sugar_boom",
			model = "models/boombox/boombox_01.mdl",
			price = sugar_boom.BoomboxPrice,
			max = 1,
			cmd = "buysugarboom",
		})
	end)
end

hook.Add("canBuyCustomEntity","sugar_preventboom_buy",function(ply, entTable)
	if entTable.ent == "sugar_boom" and sugar_boom.BlacklistedGroups and sugar_boom.BlacklistedGroups[ply:GetUserGroup()] then
		return false,false,"You are not the required group to buy this!"
	end
end)


hook.Add("playerBoughtCustomEntity", "sugar_boom_set", function(ply, entTbl, ent)
	if ent:GetClass() == "sugar_boom" and ent.CPPISetOwner then
		ent:CPPISetOwner(ply)
	end
end)


if SERVER and sugar_boom.DarkRP then
	// 76561198005432357
	hook.Add("onLockpickCompleted","sugar_boom_lockfinish",function(ply, success, ent)
		if IsValid(ent) and ent:GetClass() == "sugar_boom" then 
			ent.Locked = false 
			ent:EmitSound("buttons/latchunlocked2.wav") 
		end
	end)
end


if CLIENT then

	surface.CreateFont("boomFont_15B", {
		font = "Open Sans",
		size = 15,
		weight = 550,
		antialias = true,
	})
	
	surface.CreateFont("boomFont_18", {
		font = "Open Sans",
		size = 18,
		weight = 500
	})
	
	surface.CreateFont("boomFont_20", {
		font = "Open Sans",
		size = 20,
		weight = 500
	})

end