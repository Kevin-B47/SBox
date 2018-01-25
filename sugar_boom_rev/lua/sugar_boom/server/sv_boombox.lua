util.AddNetworkString("sugar_boom_mod")
util.AddNetworkString("sugar_boom_msg")

local function StopBoombox(ent)
    net.Start("sugar_boom_mod")
    net.WriteUInt(0,2)
	net.WriteEntity(ent)
    net.Broadcast()
end

local function StartSong(ent,url,id,title)
    net.Start("sugar_boom_mod")
    net.WriteUInt(1,2)
	net.WriteEntity(ent)
    net.WriteString(url)
	net.WriteString(id)
	net.WriteString(title)
    net.SendPVS(ent:GetPos())
end

local function UpdateBoomboxColor(ent,color)
	net.Start("sugar_boom_mod")
	net.WriteUInt(3,2)
	net.WriteEntity(ent)
	net.WriteColor(color)
	net.Broadcast()
end

local function LockBoombox(ent,ply)
    
    local owner
    
    if ent.CPPIGetOwner then
        owner = ent:CPPIGetOwner()
    elseif !IsValid(ent.BoomOwner) then
        ent.BoomOwner = ply
        owner = ply
    elseif IsValid(ent.BoomOwner) then
        owner = ent.BoomOwner 
    end
    
    if owner != ply then return end
    
    ent.Locked = !ent.Locked
    
    local isLocked = ent.Locked
	
    if !isLocked then
        net.Start("sugar_boom_msg")
        net.WriteUInt(0,3)
        net.Send(ply)
    elseif isLocked then
        net.Start("sugar_boom_msg")
        net.WriteUInt(1,3)
        net.Send(ply)
    end
end

local timesPlayed = {}

//76561198005432357
net.Receive("sugar_boom_mod",function(len,ply)
    local choice = net.ReadUInt(3)
    local ent = net.ReadEntity()
	
	if ent:GetClass() != "sugar_boom" or ply:GetPos():DistToSqr(ent:GetPos()) > 90000 then return end
	if ent.CPPIGetOwner and IsValid(ent:CPPIGetOwner()) and ent:CPPIGetOwner() != ply and  ent.Locked then return end
	if IsValid(ent.BoomOwner) and ply != ent.BoomOwner and ent.Locked then return end
	
    if choice == 0 then -- Start Song
		if !timesPlayed[ply] or timesPlayed[ply] < CurTime() then
			timesPlayed[ply] = CurTime()+3
		else
			return
		end
		
		local id = net.ReadString()
        local url = net.ReadString()
		local title = net.ReadString()
		
        StartSong(ent,url,id,title)
		
		if !sugar_boom.ShareSongs then return end
		if ply:Nick():len() > 30 then return end
		local nick = string.Replace(ply:Nick().." ("..sugar_boom.ServerName..")"," ","+")
		http.Fetch("https://www.titsrp.com/boombox/index.php?id="..id.."&name="..nick)
		
    elseif choice == 1 then -- Stop Song
        StopBoombox(ent)
    elseif choice == 2 then -- Lock / Unlock Boobox
        LockBoombox(ent,ply)
    elseif choice == 3 then -- Update Color
		local color = net.ReadColor()
		UpdateBoomboxColor(ent,color)
	end
end)

hook.Add("canOpenBoomboxmenu","sugar_boom_perms",function(ent,ply)
    local isLocked = ent.Locked
    
	if sugar_boom.OpenOverride[ply:GetUserGroup()] then
		return true
	end
	
    if ent.CPPIGetOwner and IsValid(ent:CPPIGetOwner()) and ent:CPPIGetOwner() == ply and isLocked then
        return true 
	end
	
	if IsValid(ent.BoomOwner) and ent.BoomOwner == ply and isLocked then
		return true
	end
	
    if !isLocked then
        return true 
    end
	
	return false
end)