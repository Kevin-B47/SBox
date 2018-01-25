
sugar_boom = sugar_boom or {}

--**Required** http://help.dimsemenov.com/kb/wordpress-royalslider-tutorials/wp-how-to-get-youtube-api-key--
sugar_boom.APIKey = ""

--Results given back on a search-- 
sugar_boom.APIResults = 20

-- If you dont want to share songs you play with other servers, turn this off! --
sugar_boom.ShareSongs = true
-- Put a short name of your server if the player's name + server is greater than 64 characters it will be cut off  ex) TitsRP--
sugar_boom.ServerName = "TitsRP"

--Cooldown in seconds inbetween video playing--
sugar_boom.Cooldown = 20

--How long is takes for the boombox sound to align with the player, smaller intervals work better but can have a small FPS impact if there are a lot of boomboxes (.2 - 1 is recommended)--
sugar_boom.RefreshRate = .2

-- How far people can be to hear the boombox --
sugar_boom.Distance = 150000

-- If you don't have DarkRP --
sugar_boom.DarkRP = true

-- Auto create the boombox entity in the F4 menu? --
sugar_boom.AutoCreateEntity = true

--Can people lockpick this entity? (DarkRP only)--
sugar_boom.Lockpick =  true
sugar_boom.LockpickTime = 15

sugar_boom.BoomboxPrice = 1000

--Which groups cannot buy this entity? (DarkRP only)--
sugar_boom.BlacklistedGroups = {
	--["user"] = true,
}

--Which groups can override openning the menu, even if it's locked?--
sugar_boom.OpenOverride = {
	--["superadmin"] = true,
	--["admin" ] = true,
}

















































if SERVER then
	include("sugar_boom/server/sv_boombox.lua")
	include("sugar_boom/sh_sugar_pnl_lib.lua")
	include("sugar_boom/sh_boombox.lua")
	AddCSLuaFile("sugar_boom/sh_boom_lang.lua")
	AddCSLuaFile("sugar_boom/sh_sugar_pnl_lib.lua")
	AddCSLuaFile("sugar_boom/client/cl_boombox_main.lua")
	AddCSLuaFile("sugar_boom/client/cl_boombox_derma.lua")
	AddCSLuaFile("sugar_boom/sh_boombox.lua")
else
	include("sugar_boom/sh_boom_lang.lua")
	include("sugar_boom/sh_sugar_pnl_lib.lua")
	include("sugar_boom/sh_boombox.lua")
	include("sugar_boom/client/cl_boombox_main.lua")
	include("sugar_boom/client/cl_boombox_derma.lua")
end


