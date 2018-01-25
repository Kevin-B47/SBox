local disableBoom = CreateClientConVar("cl_disableboomboxes","0",true,false,"Disables boomboxes from playing")
local playlocally = CreateClientConVar("cl_localboombox","0",true,false,"Enables local boombox play")

local boomboxes = {}

sugar_boom.BoomColors = sugar_boom.BoomColors or {}
sugar_boom.History = sugar_boom.History or {}
sugar_boom.Favorites = sugar_boom.Favorites or {}
sugar_boom.BoomboxFrm = sugar_boom.BoomboxFrm or nil
sugar_boom.Frm = sugar_boom.Frm or nil
sugar_boom.Repeat = sugar_boom.Repeat or {}
sugar_boom.VolumeControl = sugar_boom.VolumeControl or 1

local Query = sql.Query
local boomFrm

function Query(s)
	local bool = sql.Query(s)
	
	if isbool(bool) and bool == false then
		return false, sql.LastError()
	end
	return bool
end

function GetActiveBoomboxes()
	return boomboxes
end

local function EscapeValues(tbl)
	local escaped = {}
	for k,v in pairs(tbl) do
		if isnumber(v) then
			escaped[#escaped+1] = v
		elseif isstring(v) then
			escaped[#escaped+1] = sql.SQLStr(v)
		end
	end
	return escaped
end

function sugar_boom:AddHistory(tbl)
	local url = tbl["id"]
	
	if !sugar_boom.History then
		sugar_boom.History = {}
	end
	
	if !sugar_boom.History[url] then
		sugar_boom.History[url] = {id = tbl["id"], title = tbl["title"], thumbnail = tbl["thumbnail"], date = os.time()}
		local tbl = EscapeValues({url,tbl["title"],tbl["thumbnail"],os.time()})
		local q, err = Query([[INSERT INTO sugar_history VALUES (]]..table.concat(tbl,",")..[[);]])
		if err then
			print(err)
		end
	end

	if sugar_boom.Favorites[url] then
		local timesPlayed = sugar_boom.Favorites[url].timesPlayed
		sugar_boom.Favorites[url].timesPlayed = timesPlayed + 1
		local q, err = Query([[UPDATE sugar_favorites SET timesPlayed = timesPlayed + 1 WHERE id = ]]..sql.SQLStr(url)..[[;]])
		if err then
			print(err)
		end
	end
end

function sugar_boom:AddFavorite(tbl)
    if !sugar_boom.Favorites[tbl["id"]] then
        sugar_boom.Favorites[tbl["id"]] = {id = tbl["id"], title = tbl["title"], thumbnail = tbl["thumbnail"], date = os.time(), timesPlayed = 0}
		local tbl = EscapeValues({tbl["id"],tbl["title"],tbl["thumbnail"],os.time(),0})
        local q,err = Query([[INSERT INTO sugar_favorites VALUES (]]..table.concat(tbl,",")..[[);]])
		if err then
			print(err)
		end
    end
end

function sugar_boom:RemoveFavorite(id)
    Query([[DELETE FROM sugar_favorites WHERE id = ]]..sql.SQLStr(id)..[[;]])
    sugar_boom.Favorites[id] = nil
end

function sugar_boom:ClearHistory()
    Query([[DELETE FROM sugar_history]])
    sugar_boom.History = {}
end

local function CreateDB()
	file.CreateDir("sugarboomfiles")
    local q = Query([[CREATE TABLE IF NOT EXISTS sugar_history (id varchar(30), title varchar(120), thumbnail varchar(100), date long, PRIMARY KEY (id))]])
    local q = Query([[CREATE TABLE IF NOT EXISTS sugar_favorites (id varchar(30), title varchar(120), thumbnail varchar(100), date long, timesPlayed int DEFAULT 0, PRIMARY KEY (id))]])
	
	
	local fav = Query([[SELECT * FROM sugar_favorites]])
	local history = Query([[SELECT * FROM sugar_history]])
	
	if fav and istable(fav) then
		for k,v in ipairs(fav) do 
			local date = tonumber(v.date)
			v.date = date
			sugar_boom.Favorites[v.id] = v
		end
	end
	//76561198005432357
	if history and istable(history) then
		for k,v in ipairs(history) do 
			local date = tonumber(v.date)
			v.date = date
			sugar_boom.History[v.id] = v
		end
	end
	
	file.CreateDir("sugarboomfiles")
end

function sugar_boom:SetBoomColor(ent,color)
	if !IsValid(ent) then return end
	local vec = Vector(color.r,color.g,color.b):GetNormalized()
	
	if !sugar_boom.BoomColors[ent] then
		
		local matStuff = Material("models/boombox/boombox_secondary_lit"):GetKeyValues()
		
		matStuff["$flags"] = nil
		matStuff["$flags2"] = nil
		matStuff["$flags_defined"] = nil
		matStuff["$flags_defined2"] = nil
		
		sugar_boom.BoomColors[ent] = CreateMaterial("boom"..ent:EntIndex()..math.floor(ent:GetCreationTime()),"UnlitGeneric",matStuff)
		
		local tex = Material("models/boombox/boombox_secondary_lit"):GetTexture( "$basetexture" )
		sugar_boom.BoomColors[ent]:SetTexture("$basetexture",tex)
		sugar_boom.BoomColors[ent]:SetVector("$color2",vec)
		sugar_boom.BoomColors[ent]:Recompute()
		ent:SetSubMaterial(3,"!"..sugar_boom.BoomColors[ent]:GetName())
	else
		sugar_boom.BoomColors[ent]:SetVector("$color2",vec)
		sugar_boom.BoomColors[ent]:Recompute()
		ent:SetSubMaterial(3,"!"..sugar_boom.BoomColors[ent]:GetName())
	end
end

function sugar_boom:RebuildMenu()
	if IsValid(sugar_boom.BoomboxFrm) then sugar_boom.BoomboxFrm:Remove() end
	sugar_boom.BoomboxFrm = nil
end

local timesPlayed = {}

function sugar_boom:PlaySong(ent,url,id)
	http.Fetch(url,function(body)
		local tbl,dir = file.Find("sugarboomfiles/*","DATA")
		
		if tbl and #tbl >= 10 then
			for k,v in ipairs(tbl) do
				file.Delete("sugarboomfiles/"..v)
			end
		end
		
		
		if !file.Exists("sugarboomfiles/"..id..".txt","DATA") then
			file.Write("sugarboomfiles/"..id..".txt",body)	
		end
		
		local shouldNotPlay = disableBoom:GetBool()
	
		if !IsValid(ent) or shouldNotPlay then return end
		if !timesPlayed[ent] or timesPlayed[ent] < CurTime() then
			timesPlayed[ent] = CurTime() + 3
		else
			return
		end
		if boomboxes[ent] and IsValid(boomboxes[ent]) then
			boomboxes[ent]:Stop()
			boomboxes[ent] = nil
		end
			
		sound.PlayFile("data/sugarboomfiles/"..id..".txt","3d",function(station,err,errS)
			if IsValid(station) then
				station:Play()
				station:SetVolume(1)
				boomboxes[ent] = station
				
				local timerID = "sugarMoveBoomBox"..ent:EntIndex()
				if IsValid(sugar_boom.Repeat.ent) and sugar_boom.Repeat.ent == ent and sugar_boom.Repeat.fullUrl and sugar_boom.Repeat.fullUrl == url then
					timer.Create("sugar_boom_repeat",2,0,function()
						if !IsValid(sugar_boom.Repeat.ent) then 
							timer.Remove("sugar_boom_repeat")
							sugar_boom.Repeat = {}
							return 
						end
						
						if !IsValid(station) or station:GetState() == 0 then
							local shouldPlayLocal = GetConVar("cl_localboombox")
							if !shouldPlayLocal:GetBool() then
								net.Start("sugar_boom_mod")
								net.WriteUInt(0,3)
								net.WriteEntity(ent)
								net.WriteString(sugar_boom.Repeat.id)
								net.WriteString(sugar_boom.Repeat.fullUrl)
								net.WriteString(sugar_boom.Repeat.title)
								net.SendToServer()
							else
								ent.SongName = title
								sugar_boom:PlaySong(ent,sugar_boom.Repeat.fullUrl)
							end
						end
					end)
				elseif IsValid(sugar_boom.Repeat.ent) and sugar_boom.Repeat.ent == ent then
					timer.Remove("sugar_boom_repeat")
					sugar_boom.Repeat = {}
				end
				
				timer.Create("sugarMoveBoomBox"..ent:EntIndex(),sugar_boom.RefreshRate,station:GetLength(),function()
					if IsValid(ent) and IsValid(station) then
						station:SetPos(ent:GetPos())
						local dist = LocalPlayer():GetPos():DistToSqr(ent:GetPos())
						if dist > sugar_boom.Distance then
							station:SetVolume((sugar_boom.Distance/dist)*sugar_boom.VolumeControl)
						else
							station:SetVolume(sugar_boom.VolumeControl)
						end
					elseif IsValid(station) then
						station:Stop()
					else
						timer.Remove(timerID)
					end	
				end)
			else
				print(err)
				print(errS)
			end
		end)
		
	end)
end

local function StopSong(ent)
	if !IsValid(ent) then return end
	
	if IsValid(boomboxes[ent]) then
		boomboxes[ent]:Stop()
		boomboxes[ent] = nil
	end
	
	ent.SongName = ""
	
	if IsValid(sugar_boom.Repeat.ent) and sugar_boom.Repeat.ent == ent then
		timer.Remove("sugar_boom_repeat")
		sugar_boom.Repeat = {}
	end
end

net.Receive("sugar_boom_mod",function()
	local choice = net.ReadUInt(2)
	
	if choice == 0 then -- Stop song
		local ent = net.ReadEntity()
		StopSong(ent)
	elseif choice == 1 then -- PlaySong
		local ent = net.ReadEntity()
		local downloadLink = net.ReadString()
		local id = net.ReadString()
		local title = net.ReadString()
		
		ent.SongName = title
		
		sugar_boom:PlaySong(ent,downloadLink,id)
	elseif choice == 2 then -- menu
		local ent = net.ReadEntity()
		if !IsValid(sugar_boom.BoomboxFrm) then
			sugar_boom.BoomboxFrm = vgui.Create("sugar_boom_back")
			sugar_boom.BoomboxFrm:SetSize(804,404)
			sugar_boom.BoomboxFrm:BuildBoom(ent)
			sugar_boom.BoomboxFrm:Center()
			sugar_boom.BoomboxFrm:MakePopup()
		else
			sugar_boom.BoomboxFrm:SetVisible(true)
			sugar_boom.BoomboxFrm.Frm.Boombox = ent
			sugar_boom.BoomboxFrm:Center()
		end
	elseif choice == 3 then
		local ent = net.ReadEntity()
		local color = net.ReadColor()
		sugar_boom:SetBoomColor(ent,color)
	end
end)

net.Receive("sugar_boom_msg",function()
	local choice = net.ReadUInt(3)
	
	if choice == 0 then
		chat.AddText(Color(255,255,255),"You have ",Color(20,200,20),"un-locked",Color(255,255,255)," your boombox!")
	elseif choice == 1 then
		chat.AddText(Color(255,255,255),"You have ",Color(200,20,20),"locked",Color(255,255,255)," your boombox!")
	elseif choice == 2 then
	
	end
end)

hook.Add("InitPostEntity","sugar_boom_load",function()
	CreateDB()
end)

CreateDB()