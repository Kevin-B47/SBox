local history = {}
local favorites = {}
local queuedIcon = {}

local black = Color(0,0,0,254)
local grey = Color(33,33,33)
local blackish = Color(28,28,28)
local blackOutline = Color(0,0,0,220)
local white = Color(255,255,255,254)
local aWhite = Color(255,255,255)
local whiteBar = Color(255,255,255,50)
local whiteBar2 = Color(255,255,255,20)
local darkRed = Color(217, 30, 24)



local highlight = Color(117,117,117)

local favoriteMat = Material("icon16/star.png")
local glass = Material("icon16/magnifier.png")

local stringFind = string.find
local stringLower = string.lower

local function ConvertText(txt)
	return string.Replace(txt," ","+")
end

local function QueueIcon(pnl,url)
	queuedIcon[#queuedIcon+1] = {pnl = pnl, url = url}
	timer.Create("sugarqueueicons",.15,0,function()
		if #queuedIcon > 0 and IsValid(queuedIcon[1].pnl) then
			queuedIcon[1].pnl:OpenURL(queuedIcon[1].url)
			table.remove(queuedIcon,1)
		elseif queuedIcon[1] and !IsValid(queuedIcon[1].pnl) then
			table.remove(queuedIcon,1)
		elseif #queuedIcon == 0 then
			timer.Remove("sugarqueueicons")
		end
	end)
end

local PANEL = {}

function PANEL:Init()
	self:ShowCloseButton(false)
	self:SetTitle("")
end

function PANEL:OnRemove()
	table.Empty(queuedIcon)
	timer.Remove("sugarqueueicons")
end

function PANEL:Paint(w,h)
	surface.SetDrawColor(black)
	surface.DrawRect(0,0,w,h)
end

function PANEL:BuildBoom(ent)
	self.Frm = self:Add("main_boom")
	self.Frm:SetPos(2,2)
	self.Frm:SetSize(800,400)
	
	if IsValid(ent) then
		sugar_boom.Frm.Boombox = ent
	end
	
	self.Frm:BuildButtons()
	self.Frm:BuildWindows()
	self.Frm:BuildButtonFuncs()
end

vgui.Register("sugar_boom_back",PANEL,"DFrame")

local PANEL = {}

function PANEL:Init()
    sugar_boom.Frm = self
	self.Cooldown = 0
	self.Buttons = {}
	self.ButtonTxt = {sugar_boom.Lang["Search"],sugar_boom.Lang["View Favorites"],sugar_boom.Lang["View History"],sugar_boom.Lang["Community"],sugar_boom.Lang["Settings"]}
	self.SearchID = sugar_boom.Lang["Search"]
end

function PANEL:Paint(w,h)

    surface.SetDrawColor(blackish)
	surface.DrawRect(0,0,w,h)
end

function PANEL:BuildButtons()

	self.LeftBox = self:Add("sugar_boom_left")
	self.LeftBox:SetSize(150,self:GetTall())

	for k,v in ipairs(self.ButtonTxt) do
		
		local butt = self.LeftBox:Add("DButton")
		butt:SetText(v)
		butt:SetTextColor(white)
		butt:SetFontInternal("boomFont_18")
		butt:SetSize(self.LeftBox:GetWide(),31)
		butt:SetPos(0,(k*31)-31)
		butt:SetContentAlignment(4)
		butt:SetTextInset(15,0)
		butt.Alpha = 0
		butt.Color = Color(177,177,177,0)
		butt.ID = v
		
		// {{ user_id }}
		
		function butt:Paint(w,h)
			local x,y = self:GetTextInset()
			local hovered = self:IsHovered()
			if hovered and x < 25 then
				self:SetTextInset(x+1,y)
			elseif !hovered and x > 15 then
				self:SetTextInset(x-1,y)
			end
			surface.SetDrawColor(whiteBar2)
			surface.DrawRect(0,h-1,w,1)
			
			if hovered and self.Alpha < 50 then
				self.Alpha = Lerp(FrameTime()*10,self.Alpha,50)
			elseif !hovered and self.Alpha > 0 then
				self.Alpha = Lerp(FrameTime()*10,self.Alpha,0)
			end
			
			self.Color.a = self.Alpha
			
			surface.SetDrawColor(self.Color)
			surface.DrawRect(0,0,w,h)
			
		end
		self.Buttons[#self.Buttons+1] = butt
	end
	
	self.EndSong = self:Add("DButton")
	self.EndSong:SetText(sugar_boom.Lang["Stop Song"])
	self.EndSong:SetPos(0,self.LeftBox:GetTall()-31)
	self.EndSong:SetSize(self.LeftBox:GetWide()-1,31)
	self.EndSong:SetExpensiveShadow( 1, Color(0,0,0) )
	self.EndSong:SetTextColor(Color(255,255,255))
	self.EndSong.Cooldown = 0
	function self.EndSong:Paint(w,h)
		surface.SetDrawColor(darkRed)
		surface.DrawRect(0,0,w,h)
	end
	
	function self.EndSong:DoClick()
		if self.Cooldown < CurTime() then
			net.Start("sugar_boom_mod")
			net.WriteUInt(1,3)
			net.WriteEntity(sugar_boom.Frm.Boombox)
			net.SendToServer()
			self.Cooldown = CurTime() + 5
			chat.AddText(Color(255,255,255),sugar_boom.Lang["Stopping song!"])
			self:SetVisible(false)
		end
	end
	
	if IsValid(self.Boombox) and GetActiveBoomboxes()[self.Boombox] then
		self.EndSong:SetVisible(true)
	else
		self.EndSong:SetVisible(false)
	end
	
end

function PANEL:BuildButtonFuncs()
	for k,v in ipairs(self.Buttons) do
		function v:DoClick()
			if sugar_boom.Frm.Panels[self.ID] then
				for k,v in pairs(sugar_boom.Frm.Panels) do
					v:SetVisible(false)
				end
				
				sugar_boom.Frm.Panels[self.ID]:SetVisible(true)
				sugar_boom.Frm.SearchID = self.ID
				
				if self.ID == sugar_boom.Lang["View Favorites"] then
					sugar_boom.Frm.FavoritesPnl:PopulateFavorites()
				elseif self.ID == sugar_boom.Lang["View History"] then
					sugar_boom.Frm.HistoryPnl:PopulateHistory()
				elseif self.ID == sugar_boom.Lang["Community"] then
					sugar_boom.Frm.CommunityPnl:PopulateCommunity()
				end
			end
		end
	end
end

function PANEL:BuildWindows()
	
	local x = self.LeftBox:GetWide()
	self.SearchBar = self:Add("sugar_vid_search")
	self.SearchBar:SetPos(x+5,5)
	self.SearchBar:SetSize(200,20)
	
	self.VolumeControl = self:Add("sugar_boom_volume")
	self.VolumeControl:SetPos(self.SearchBar:GetPos()+150,15)
	self.VolumeControl:SetSize(200,20)
	
	self.VolumeText = self:Add("DLabel")
	self.VolumeText:SetText("100%")
	self.VolumeText:SetFontInternal("boomFont_15B")
	self.VolumeText:SetPos(self.VolumeControl:GetPos()+215,5)
	self.VolumeText:SetTextColor(Color(2555,255,255))
	
	self.VolumeControl.VolumeText = self.VolumeText
	
	self.SearchButt = self:Add("DButton")
    self.SearchButt:SetPos(self.SearchBar:GetPos()+self.SearchBar:GetWide(),5)
	self.SearchButt:SetSize(20,self.SearchBar:GetTall())
    self.SearchButt:SetText("")
	
	self.Search = self:Add("sugar_scroll_boom")
	self.Search:SetSize(self:GetWide()-x+3,self:GetTall()-30)
	self.Search:SetPos(x,30)
	self.Search.ID = sugar_boom.Lang["Search"]
	self.Search.SearchBar = self.SearchButt
	
	self.FavoritesPnl = self:Add("sugar_scroll_boom")
	self.FavoritesPnl:SetSize(self:GetWide()-x+3,self:GetTall()-30)
	self.FavoritesPnl:SetPos(x,30)
	self.FavoritesPnl:SetVisible(false)
	self.FavoritesPnl.ID = sugar_boom.Lang["View Favorites"]
	
	self.HistoryPnl = self:Add("sugar_scroll_boom")
	self.HistoryPnl:SetSize(self:GetWide()-x+3,self:GetTall()-30)
	self.HistoryPnl:SetPos(x,30)
	self.HistoryPnl:SetVisible(false)
	self.HistoryPnl.ID = sugar_boom.Lang["View History"]
	
	self.CommunityPnl = self:Add("sugar_scroll_boom")
	self.CommunityPnl:SetSize(self:GetWide()-x+3,self:GetTall()-30)
	self.CommunityPnl:SetPos(x,30)
	self.CommunityPnl:SetVisible(false)
	self.CommunityPnl.ID = sugar_boom.Lang["Community"]
	
	self.SettingsPnl = self:Add("sugar_scroll_boom")
	self.SettingsPnl:SetSize(self:GetWide()-x+3,self:GetTall()-30)
	self.SettingsPnl:SetPos(x,30)
	self.SettingsPnl:BuildSettings()
	self.SettingsPnl:SetVisible(false)
	self.SettingsPnl.ID = sugar_boom.Lang["Settings"]
	
	self.Panels = {
		[sugar_boom.Lang["Search"]] = self.Search,
		[sugar_boom.Lang["View Favorites"]] = self.FavoritesPnl,
		[sugar_boom.Lang["View History"]] = self.HistoryPnl,
		[sugar_boom.Lang["Settings"]] = self.SettingsPnl,
		[sugar_boom.Lang["Community"]] = self.CommunityPnl,
	}
	
	function self.SearchButt:Paint(w,h)
		surface.SetDrawColor(grey)
		surface.DrawRect(0,0,w,h)
		
		surface.SetDrawColor(whiteBar2)
		surface.DrawOutlinedRect(0,0,w,h)
		
		surface.SetDrawColor(white)
		surface.SetMaterial(glass)
		surface.DrawTexturedRect(2,2,16,16)
	end
	
	function self.SearchButt:DoClick()
		return sugar_boom.Frm.Search:SearchVideo(sugar_boom.Frm.SearchBar:GetValue())
	end
	
	
	
	self.CloseButton = self:Add("DButton")
	self.CloseButton:SetText("X")
	self.CloseButton:SetTextColor(Color(255,255,255))
	self.CloseButton:SetSize(18,18)
	self.CloseButton:SetFontInternal("boomFont_18")
	self.CloseButton:SetPos(self:GetWide()-20,0)
	
	function self.CloseButton:DoClick()
		if sugar_boom.QueuedColor != nil and istable(sugar_boom.QueuedColor) then
			
			local color = Color(sugar_boom.QueuedColor.r,sugar_boom.QueuedColor.g,sugar_boom.QueuedColor.b)
			
			if !IsColor(color) then return end
			net.Start("sugar_boom_mod")
			net.WriteUInt(3,3)
			net.WriteEntity(sugar_boom.Frm.Boombox)
			net.WriteColor(color)
			net.SendToServer()
		end
		sugar_boom.QueuedColor = nil
		sugar_boom.Frm:GetParent():SetVisible(false)
	end
	
	function self.CloseButton:Paint(w,h)
		
	end
end

function PANEL:AddToCategory(tbl,category)

	local pnls = {
		[sugar_boom.Lang["History"]] = sugar_boom.Frm.HistoryPnl,
		[sugar_boom.Lang["Favorites"]] = sugar_boom.Frm.FavoritesPnl,
		[sugar_boom.Lang["Community"]] = sugar_boom.Frm.CommunityPnl
	}
	
	local found = false
	
	
	for k,v in pairs(pnls[category].VideoPnls) do
		if (v.id == tbl.id or v.thumbnail == tbl.thumbnail) and IsValid(v.pnl) then
			found = k
		end
	end

	if !found then
		local vid = pnls[category]:Add("sugar_videopnl")
		vid:SetSize(pnls[category]:GetWide(),92)
		vid:SetPos(0,0)
		if category == sugar_boom.Lang["History"] then
			vid:SetVideoHistory(tbl)
			table.insert(pnls[category].VideoPnls,1,{pnl = vid, thumbnail = tbl.thumbnail, title = tbl.title, id = tbl.id})
		elseif category == sugar_boom.Lang["Favorites"] then
			tbl.timesPlayed = 0
			vid:SetVideoFavorite(tbl)
			table.insert(pnls[category].VideoPnls,1,{pnl = vid, thumbnail = tbl.thumbnail, title = tbl.title, id = tbl.id, timesPlayed = 0})
		end
		vid:SetVisible(false)
		vid[category] = true
		if !pnls[category].VideoIDS then
			pnls[category].VideoIDS[tbl.id] = {pnl = vid, tbl = tbl}
		end
	elseif found and pnls[category].VideoPnls[found] then
		local swapToOne = pnls[category].VideoPnls[found]
		
		table.remove(pnls[category].VideoPnls,found)
		table.insert(pnls[category].VideoPnls,1,swapToOne)
		
	end
end

vgui.Register("main_boom",PANEL,"DPanel")

local PANEL = {}

function PANEL:Init()
   self.VideoPnls = {} 
   self.CD = 0
   self.VideoIDS = {}
   self.FavoriteIDS = {}
   self.HistoryIDS = {}
   
   self.WasRan = false
   
   local bar = self:GetVBar()
   
   function bar:Paint(w,h)
	
	end

	function bar.btnUp:Paint(w,h)
		
	end

	function bar.btnDown:Paint(w,h)
		
	end


	function bar.btnGrip:Paint(w,h)
		draw.RoundedBox(0, SugarConvertWidth(4), 0, w/3, h, white)
	end
end

function PANEL:Paint(w,h)
    --surface.SetDrawColor(Color(200,20,20))
	--surface.DrawRect(0,0,w,h)
end

function PANEL:RemoveAll()
	for k,v in pairs(self.VideoPnls) do
		if IsValid(v) then
			v:Remove()
		end
	end
	table.Empty(self.VideoPnls)
	table.Empty(self.VideoIDS)
end

function PANEL:ResetHistory()
	for k,v in pairs(self.VideoPnls) do
		if IsValid(v.pnl) then
			v.pnl:Remove()
		end
	end
	table.Empty(self.VideoPnls)
	sugar_boom:ClearHistory()
end

function PANEL:PopulateCommunity()
	self:RemoveAll()
	
	local count = 0
	if self.CD < CurTime() then
		self.CD = CurTime() + 2
	else
		return
	end
	http.Fetch("https://www.titsrp.com/boombox/fetch.php?",function(body)
		local json = util.JSONToTable(body)
		local count = 0
		for k,v in ipairs(json) do
			http.Fetch("https://www.googleapis.com/youtube/v3/videos?id="..v.id.."&key="..sugar_boom.APIKey.."&fields=items(snippet(title))&part=snippet",function(body,err)
				local tbl = util.JSONToTable(body)
				if !IsValid(sugar_boom.Frm) or !tbl or !tbl.items then return end
				for item,tbl in ipairs(tbl.items) do
					if !tbl.snippet  or !tbl.snippet.title then continue end
					local vidData = {
						["url"] = v.id,
						["title"] = tbl.snippet.title,
						["thumbnail"] = "https://img.youtube.com/vi/"..v.id.."/default.jpg",
						["timesPlayed"] = v.timesplayed,
						["requester"] = v.name,
					}
					
					if !IsValid(self) then break end
				
					local vid = self:Add("sugar_videopnl")
					vid:SetSize(self:GetWide(),92)
					vid:SetPos(0,count*93)
					vid:SetCommunity(vidData)
					vid.Community = true
					count = count + 1
					self.VideoPnls[#self.VideoPnls+1] = vid
					self.VideoIDS[v.id] = {pnl = vid, tbl = vidData}
				end
			end)
		end
	end)
end

function PANEL:PopulateFavorites(term)
	local count = 0
	
	local sortByAdded = {}
	
	if !self.WasRan then -- Initial build
		self.WasRan = true
		for k,v in pairs(sugar_boom.Favorites) do
			sortByAdded[#sortByAdded+1] = v
		end
		table.SortByMember(sortByAdded,"date")
		for k,v in ipairs(sortByAdded) do
			local vid = self:Add("sugar_videopnl")
			vid:SetSize(self:GetWide(),92)
			vid:SetPos(0,count*93)
			vid:SetVideoFavorite(v)
			vid.Favorites = true
			count = count + 1
			self.VideoPnls[#self.VideoPnls+1] = {pnl = vid, title = v.title, id = v.id}
			if !self.VideoIDS then
				self.VideoIDS[v.id] = {pnl = vid, tbl = v}
			end
		end
	end
	
	count = 0
	
	if term then
		local lowerTerm = stringLower(term)
		for k,v in pairs(self.VideoPnls) do
			local isValid = IsValid(v.pnl)
			if stringFind(stringLower(v.title),lowerTerm,1,true) and isValid and sugar_boom.Favorites[v.id] then
				v.pnl:SetPos(0,count*93)
				v.pnl:SetVisible(true)
				count = count + 1
			elseif isValid then
				v.pnl:SetVisible(false)
			end
		end
	else
		for k,v in pairs(self.VideoPnls) do
			local isValid = IsValid(v.pnl)
			if isValid and sugar_boom.Favorites[v.id] then
				v.pnl:SetPos(0,count*93)
				v.pnl:SetVisible(true)
				count = count + 1
			elseif isValid then
				v.pnl:SetVisible(false)
			end
		end
	end
end

function PANEL:PopulateHistory(term)
	local count = 0
	
	local sortByAdded = {}
	
	if !self.WasRan then -- Initial build
		self.WasRan = true
		for k,v in pairs(sugar_boom.History) do
			sortByAdded[#sortByAdded+1] = v
		end
		table.SortByMember(sortByAdded,"date")
		for k,v in ipairs(sortByAdded) do
			local vid = self:Add("sugar_videopnl")
			vid:SetSize(self:GetWide(),92)
			vid:SetPos(0,count*93)
			vid:SetVideoHistory(v)
			vid.History = true
			count = count + 1
			self.VideoPnls[#self.VideoPnls+1] = {pnl = vid, title = v.title, id = v.id}
			if !self.VideoIDS then
				self.VideoIDS[v.id] = {pnl = vid, tbl = v}
			end
		end
	end
	
	count = 0
	
	if term then
		local lowerTerm = stringLower(term)
		for k,v in pairs(self.VideoPnls) do
			if stringFind(stringLower(v.title),lowerTerm,1,true) and IsValid(v.pnl) then
				v.pnl:SetPos(0,count*93)
				v.pnl:SetVisible(true)
				count = count + 1
			elseif IsValid(v.pnl) then
				v.pnl:SetVisible(false)
			end
		end
	else
		for k,v in pairs(self.VideoPnls) do
			if IsValid(v.pnl) then
				v.pnl:SetPos(0,count*93)
				v.pnl:SetVisible(true)
				count = count + 1
			end
		end
	end
end

function PANEL:SearchVideo(term)
	local newText = ConvertText(sugar_boom.Frm.SearchBar:GetValue())
	self:RemoveAll()
	if !sugar_boom.APIKey or sugar_boom.APIKey:len() < 5 then
		chat.AddText(Color(255,255,255),sugar_boom.Lang["InvalidAPIKey"])
		return                         
	end                                
    http.Fetch("https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults="..sugar_boom.APIResults.."&order=viewCount&q="..newText.."&type=video&key="..sugar_boom.APIKey,function(body,err)
		local tbl = util.JSONToTable(body)
		local count = 0
		local ids = {}
		if !IsValid(sugar_boom.Frm) or !tbl or !tbl.items then return end
		for k,v in ipairs(tbl.items) do
			if !v.snippet  or !v.snippet.title then continue end
			local vidData = {
				["url"] = v.id.videoId,
				["title"] = v.snippet.title,
				["icon"] = v.snippet.thumbnails.default.url,
				["views"] = 0,
				["likes"] = 0,
				["dislikes"] = 0,
				["length"] = 0,
			}
		
			local vid = self:Add("sugar_videopnl")
			vid:SetSize(self:GetWide(),92)
			vid:SetPos(0,count*93)
			vid:SetVideo(vidData)
			vid.Search = true
			count = count + 1
			self.VideoPnls[#self.VideoPnls+1] = vid
			self.VideoIDS[v.id.videoId] = {pnl = vid, tbl = vidData}
			
			ids[#ids+1] = v.id.videoId
		end
		
		http.Fetch("https://www.googleapis.com/youtube/v3/videos?part=statistics,contentDetails&id="..table.concat(ids,",").."&key="..sugar_boom.APIKey,function(body,err)
			local json = util.JSONToTable(body)
			if !json or !json["items"] then return end
			for k,v in ipairs(json["items"]) do
				if self.VideoIDS[v.id] then
					self.VideoIDS[v.id]["tbl"].views = v.statistics.viewCount
					self.VideoIDS[v.id]["tbl"].dislikes = v.statistics.dislikeCount
					self.VideoIDS[v.id]["tbl"].likes = v.statistics.likeCount
					self.VideoIDS[v.id]["tbl"].length = string.sub(v.contentDetails.duration,3)
					self.VideoIDS[v.id].pnl:SetVideo(self.VideoIDS[v.id].tbl)
					self.VideoIDS[v.id].pnl.VideoLength = string.sub(v.contentDetails.duration,3)
				end
			end
		end)
	end)
end

function PANEL:BuildSettings()
	local boomdisabled = GetConVar("cl_disableboomboxes")
	local boomlocal = GetConVar("cl_localboombox")
	
	
	local disableBoomAudioOpt = sugar_boom.Lang["Disable All Boombox Audio"]
	local playLocalOnly = sugar_boom.Lang["Play Songs Local"]

	if boomdisabled:GetBool() then
		disableBoomAudioOpt = sugar_boom.Lang["You will no longer be able to hear boombox audio"]
	end
	
	if boomlocal:GetBool() then
		playLocalOnly = sugar_boom.Lang["Play Songs For Everyone"]
	end
	
	local settings = {
		{txt = sugar_boom.Lang["Lock Boombox"],func = function(butt)
			if IsValid(sugar_boom.Frm.Boombox) then
				net.Start("sugar_boom_mod")
				net.WriteUInt(2,3)
				net.WriteEntity(sugar_boom.Frm.Boombox)
				net.SendToServer()
			end
		end},
		{txt = disableBoomAudioOpt,func = function(butt)
			boomdisabled:SetBool(!boomdisabled:GetBool())
			
			if boomdisabled:GetBool() then
				LocalPlayer():ConCommand("stopsound")
				chat.AddText(Color(255,255,255),sugar_boom.Lang["You will no longer be able to hear boombox audio"])
				butt:SetText(sugar_boom.Lang["Enable All Boombox Audio"])
			else
				chat.AddText(Color(255,255,255),sugar_boom.Lang["You will be able to now hear boombox audio"])
				butt:SetText(sugar_boom.Lang["Disable All Boombox Audio"])
			end
		end},
		{txt = playLocalOnly,func = function(butt)
			boomlocal:SetBool(!boomlocal:GetBool())
			
			if boomlocal:GetBool() then
				LocalPlayer():ConCommand("stopsound")
				chat.AddText(Color(255,255,255),sugar_boom.Lang["Boombox songs will only play for you"])
				butt:SetText(sugar_boom.Lang["Play Songs For Everyone"])
			else
				chat.AddText(Color(255,255,255),sugar_boom.Lang["Boombox songs will only play for everyone around your boombox"])
				butt:SetText(sugar_boom.Lang["Play Songs Local"])
			end
		end},
		{txt = sugar_boom.Lang["Set Boombox Color"],func = function()
			if !IsValid(sugar_boom.Frm.BoomColor) then
				sugar_boom.Frm.BoomColor = sugar_boom.Frm.SettingsPnl:Add("DColorMixer")
				sugar_boom.Frm.BoomColor:SetPalette(false)
				sugar_boom.Frm.BoomColor:SetAlphaBar(false)
				sugar_boom.Frm.BoomColor:SetWangs(false)
				sugar_boom.Frm.BoomColor:SetSize(sugar_boom.Frm.SettingsPnl:GetWide()-150,75)
				sugar_boom.Frm.BoomColor:SetPos(75,sugar_boom.Frm.SettingsPnl:GetTall()-75)
				
				function sugar_boom.Frm.BoomColor:ValueChanged(col)
					sugar_boom:SetBoomColor(sugar_boom.Frm.Boombox,col)
					sugar_boom.QueuedColor = col
				end
				
			elseif IsValid(sugar_boom.Frm.BoomColor) then
				sugar_boom.Frm.BoomColor:Remove()
			end
		end},
		{txt = sugar_boom.Lang["Clear History"],func = function()
			sugar_boom.Frm.HistoryPnl:ResetHistory()
			chat.AddText(Color(255,255,255),sugar_boom.Lang["History was cleared"])
		end},
		{txt = sugar_boom.Lang["Rebuild Frame"],func = function()
			sugar_boom:RebuildMenu()
			chat.AddText(Color(255,255,255),sugar_boom.Lang["Frame will be rebuilt on the next open"])
		end},
	 }
	
	for k,v in ipairs(settings) do
		local butt = self:Add("DButton")
		
		butt:SetSize(self:GetWide()-150,40)
		butt:SetPos(75,((k-1)*45) + 20)
		butt:SetText(v.txt)
		butt:SetFontInternal("boomFont_20")
		butt:SetTextColor(Color(255,255,255,100))
		
		function butt:Paint(w,h)
			if self:IsHovered() then
				surface.SetDrawColor(aWhite)
				surface.DrawOutlinedRect(0,0,w,h)
				self:SetTextColor(aWhite)
			else
				surface.SetDrawColor(whiteBar)
				surface.DrawOutlinedRect(0,0,w,h)
				self:SetTextColor(whiteBar)
			end
		end
		
		function butt:DoClick()
			LocalPlayer():EmitSound("garrysmod/ui_click.wav")
			v.func(self)
		end
	end
	
end

vgui.Register("sugar_scroll_boom",PANEL,"DScrollPanel")

local PANEL = {}

function PANEL:Init()
	self:SetMouseInputEnabled(true)
	self.Color = Color(33,33,33)
end

function PANEL:Paint(w,h)
	if self:IsHovered() and self.Color.r < 55 then
		self.Color = SugarLerpColor(FrameTime()*10,self.Color,Color(55,55,55))
	elseif !self:IsHovered() and self.Color.r > 33 then
		self.Color = SugarLerpColor(FrameTime()*10,self.Color,Color(33,33,33))
	end
	
	surface.SetDrawColor(self.Color)
	surface.DrawRect(0,0,w,h)
end

function PANEL:SetVideoHistory(tbl)
	if !self.Thumb then
		self.Thumb = self:Add("HTML")
		self.Thumb:SetSize(120,90)
		self.Thumb:SetPos(0,0)
		QueueIcon(self.Thumb,tbl["thumbnail"])
		--self.Thumb:OpenURL(tbl["thumbnail"])
	else
		self.Thumb:SetText(tbl["thumbnail"])
	end
	
	if !self.Title then
		self.Title = self:Add("DLabel")
		self.Title:SetText(tbl["title"])
		self.Title:SetTextColor(Color(255,255,255))
		self.Title:SetFontInternal("boomFont_20")
		self.Title:SetSize(self:GetWide(),20)
		self.Title:SetPos(130,10)
		self.Title:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.Title:SetText(tbl["title"])
	end
	
	self.URL = tbl["id"]
	self.Icon = tbl["thumbnail"]
	
	if !self.Time then
		self.Time = self:Add("DLabel")
		self.Time:SetText(sugar_boom.Lang["Watched At"]..": "..os.date("%m/%d/%Y - %H:%M:%S",tonumber(tbl["date"])))
		self.Time:SetTextColor(Color(200,200,200,150))
		self.Time:SetFontInternal("boomFont_15B")
		self.Time:SetSize(self:GetWide(),20)
		self.Time:SetPos(130,40)
		self.Time:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.Time:SetText(sugar_boom.Lang["Watched At"]..": "..os.date("%m/%d/%Y - %H:%M:%S",tonumber(tbl["date"])))
	end
	
	if !self.AddFavorite then
		self.AddFavorite = self:Add("sugar_boom_favorite")
		self.AddFavorite:SetText("")
		self.AddFavorite:SetSize(16,16)
		self.AddFavorite:SetToolTip(sugar_boom.Lang["Add to favorites"])
		self.AddFavorite:SetPos(self:GetWide()-40,self:GetTall()-20)
		self.AddFavorite:SetTextColor(Color(255,255,255))
		self.AddFavorite:SetVideoData(tbl["id"],tbl["thumbnail"],tbl["title"])
	end
end

function PANEL:SetCommunity(tbl)
	local cSelf = self
	
	if !self.Thumb then
		self.Thumb = self:Add("HTML")
		self.Thumb:SetSize(120,90)
		self.Thumb:SetPos(0,0)
		QueueIcon(self.Thumb,tbl["thumbnail"])
		--self.Thumb:OpenURL(tbl["icon"]) {{ user_id }}
	else
		self.Thumb:SetText(tbl["thumbnail"])
	end
	
	self.Icon = tbl["thumbnail"]
    
	if !self.Title then
		self.Title = self:Add("DLabel")
		self.Title:SetText(tbl["title"])
		self.Title:SetTextColor(Color(255,255,255))
		self.Title:SetFontInternal("boomFont_20")
		self.Title:SetSize(self:GetWide(),20)
		self.Title:SetPos(130,10)
		self.Title:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.Title:SetText(tbl["title"])
	end
    
    self.URL = tbl["url"]
    
	if !self.Requester then
		self.Requester = self:Add("DLabel")
		self.Requester:SetText(sugar_boom.Lang["Requested By"]..": "..tbl.requester)
		self.Requester:SetTextColor(Color(200,200,200,150))
		self.Requester:SetFontInternal("boomFont_15B")
		self.Requester:SetPos(130,40)
		self.Requester:SetSize(self:GetWide(),18)
		self.Requester:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.Requester:SetText(sugar_boom.Lang["Requested By"]..": "..tbl.requester)
	end
	
	if !self.TimesPlayed then
		self.TimesPlayed = self:Add("DLabel")
		self.TimesPlayed:SetText(sugar_boom.Lang["Times Played"]..": "..tbl.timesPlayed)
		self.TimesPlayed:SetTextColor(Color(200,200,200,150))
		self.TimesPlayed:SetFontInternal("boomFont_15B")
		self.TimesPlayed:SetPos(130,60)
		self.TimesPlayed:SetSize(self:GetWide(),18)
		self.TimesPlayed:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.TimesPlayed:SetText(sugar_boom.Lang["Times Played"]..": "..tbl.timesPlayed)
	end
    
    
	if !self.AddFavorite then
		self.AddFavorite = self:Add("sugar_boom_favorite")
		self.AddFavorite:SetText("")
		self.AddFavorite:SetSize(16,16)
		self.AddFavorite:SetPos(self:GetWide()-40,self:GetTall()-20)
		self.AddFavorite:SetTextColor(Color(255,255,255))
		self.AddFavorite:SetVideoData(cSelf.URL,cSelf.Icon,tbl["title"])
	end
end

function PANEL:SetVideoFavorite(tbl)
	if !self.Thumb then
		self.Thumb = self:Add("HTML")
		self.Thumb:SetSize(120,90)
		self.Thumb:SetPos(0,0)
		QueueIcon(self.Thumb,tbl["thumbnail"])
		--self.Thumb:OpenURL(tbl["thumbnail"])
	else
		self.Thumb:SetText(tbl["thumbnail"])
	end
	
	if !self.Title then
		self.Title = self:Add("DLabel")
		self.Title:SetText(tbl["title"])
		self.Title:SetTextColor(Color(255,255,255))
		self.Title:SetFontInternal("boomFont_20")
		self.Title:SetSize(self:GetWide(),20)
		self.Title:SetPos(130,10)
		self.Title:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.Title:SetText(tbl["title"])
	end
	
	self.URL = tbl["id"]
	self.Icon = tbl["thumbnail"]
	
	if !self.Time then
		self.Time = self:Add("DLabel")
		self.Time:SetText(sugar_boom.Lang["Favorited At"]..": "..os.date("%m/%d/%Y - %H:%M:%S",tonumber(tbl["date"])))
		self.Time:SetTextColor(Color(200,200,200,150))
		self.Time:SetFontInternal("boomFont_15B")
		self.Time:SetSize(self:GetWide(),20)
		self.Time:SetPos(130,40)
		self.Time:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.Time:SetText(sugar_boom.Lang["Favorited At"]..": "..os.date("%m/%d/%Y - %H:%M:%S",tonumber(tbl["date"])))
	end
	
	if !self.Played then
		self.Played = self:Add("DLabel")
		self.Played:SetText(sugar_boom.Lang["Played"]..": "..tbl["timesPlayed"].." time(s)")
		self.Played:SetTextColor(Color(200,200,200,150))
		self.Played:SetFontInternal("boomFont_15B")
		self.Played:SetSize(self:GetWide(),20)
		self.Played:SetPos(130,60)
		self.Played:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.Played:SetText(sugar_boom.Lang["Played"]..": "..tbl["timesPlayed"].." time(s)")
	end
	
	if !self.AddFavorite then
		self.AddFavorite = self:Add("sugar_boom_favorite")
		self.AddFavorite:SetText("")
		self.AddFavorite:SetSize(16,16)
		self.AddFavorite:SetToolTip(sugar_boom.Lang["Add to favorites"])
		self.AddFavorite:SetPos(self:GetWide()-40,self:GetTall()-20)
		self.AddFavorite:SetTextColor(Color(255,255,255))
		self.AddFavorite:SetVideoData(tbl["id"],tbl["thumbnail"],tbl["title"])
	end
end

function PANEL:SetVideo(tbl)

	local cSelf = self
	
	local views = FormatNumber(tonumber(tbl["views"]))
	local likes = FormatNumber(tonumber(tbl["likes"]))
	local dislikes = FormatNumber(tonumber(tbl["dislikes"]))
	local length = tbl["length"]
	
	if !length then
		length = "No Length"
	end
	
	
	if !self.Thumb then
		self.Thumb = self:Add("HTML")
		self.Thumb:SetSize(120,90)
		self.Thumb:SetPos(0,0)
		QueueIcon(self.Thumb,tbl["icon"])
		--self.Thumb:OpenURL(tbl["icon"]) {{ user_id }}
	else
		self.Thumb:SetText(tbl["icon"])
	end
	
	self.Icon = tbl["icon"]
    
	if !self.Title then
		self.Title = self:Add("DLabel")
		self.Title:SetText(tbl["title"])
		self.Title:SetTextColor(Color(255,255,255))
		self.Title:SetFontInternal("boomFont_20")
		self.Title:SetSize(self:GetWide(),20)
		self.Title:SetPos(130,10)
		self.Title:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.Title:SetText(tbl["title"])
	end
    
    self.URL = tbl["url"]
    
	if !self.Views then
		self.Views = self:Add("DLabel")
		self.Views:SetText(sugar_boom.Lang["Views"]..": "..views)
		self.Views:SetTextColor(Color(200,200,200,150))
		self.Views:SetFontInternal("boomFont_15B")
		self.Views:SetPos(130,40)
		self.Views:SetSize(self:GetWide(),18)
		self.Views:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.Views:SetText(sugar_boom.Lang["Views"]..": "..views)
	end
	
	if !self.Likes then
		self.Likes = self:Add("DLabel")
		self.Likes:SetText(sugar_boom.Lang["Likes"]..": "..likes)
		self.Likes:SetTextColor(Color(200,200,200,150))
		self.Likes:SetFontInternal("boomFont_15B")
		self.Likes:SetPos(130,60)
		self.Likes:SetSize(self:GetWide(),18)
		self.Likes:SetExpensiveShadow( 1, Color(0,0,0) )
	else
		self.Likes:SetText(sugar_boom.Lang["Likes"]..": "..likes)
	end
	
	if !self.Dislikes then
		self.Dislikes = self:Add("DLabel")
		self.Dislikes:SetText(sugar_boom.Lang["Dislikes"]..": "..dislikes)
		self.Dislikes:SetTextColor(Color(200,200,200,150))
		self.Dislikes:SetFontInternal("boomFont_15B")
		self.Dislikes:SetSize(self:GetWide(),18)
		self.Dislikes:SetExpensiveShadow( 1, Color(0,0,0) )
		self.Dislikes:SetPos(self.Likes:GetPos()+GetSugarTextSize(self.Likes:GetValue(),"boomFont_15B")+10,60)
	else
		self.Dislikes:SetText(sugar_boom.Lang["Dislikes"]..": "..dislikes)
		self.Dislikes:SetPos(self.Likes:GetPos()+GetSugarTextSize(self.Likes:GetValue(),"boomFont_15B")+10,60)
	end
	
	if !self.Duration then
		self.Duration = self:Add("DLabel")
		self.Duration:SetText(sugar_boom.Lang["Length"]..": "..length)
		self.Duration:SetTextColor(Color(200,200,200,150))
		self.Duration:SetFontInternal("boomFont_15B")
		self.Duration:SetSize(self:GetWide(),18)
		self.Duration:SetExpensiveShadow( 1, Color(0,0,0) )
		self.Duration:SetPos(self.Dislikes:GetPos()+GetSugarTextSize(self.Dislikes:GetValue(),"boomFont_15B")+10,60)
	else
		self.Duration:SetText(sugar_boom.Lang["Length"]..": "..length)
		self.Duration:SetPos(self.Dislikes:GetPos()+GetSugarTextSize(self.Dislikes:GetValue(),"boomFont_15B")+10,60)
	end
    
    
	if !self.AddFavorite then
		self.AddFavorite = self:Add("sugar_boom_favorite")
		self.AddFavorite:SetText("")
		self.AddFavorite:SetSize(16,16)
		self.AddFavorite:SetPos(self:GetWide()-40,self:GetTall()-20)
		self.AddFavorite:SetTextColor(Color(255,255,255))
		self.AddFavorite:SetVideoData(cSelf.URL,cSelf.Icon,tbl["title"])
	end
end

function PANEL:ListenToVideo(url,icon,isRepeat,length)
	local title = self.Title:GetValue()
	local isConverting = false
	
	function Listen(downloadLink)
		timer.Remove("SugarBoomCheck")
		if IsValid(sugar_boom.Frm.Boombox) then
			timer.Simple(2,function()
				if IsValid(sugar_boom.Frm) and IsValid(sugar_boom.Frm.EndSong) then
					sugar_boom.Frm.EndSong:SetVisible(true)
				end
			end)
			
			local data = {id = url, thumbnail = icon ,title = title}
			sugar_boom:AddHistory(data)
			sugar_boom.Frm:AddToCategory(data,sugar_boom.Lang["History"])
		
			local shouldPlayLocal = GetConVar("cl_localboombox")
			
			if !shouldPlayLocal:GetBool() then
				net.Start("sugar_boom_mod")
				net.WriteUInt(0,3)
				net.WriteEntity(sugar_boom.Frm.Boombox)
				net.WriteString(url)
				net.WriteString(downloadLink)
				net.WriteString(title)
				net.SendToServer()
			else
				sugar_boom.Frm.Boombox:SetNW2String("song",title)
				sugar_boom:PlaySong(sugar_boom.Frm.Boombox,downloadLink,url)
			end
			if isRepeat then
				sugar_boom.Repeat = {ent = sugar_boom.Frm.Boombox, id = url, fullUrl = downloadLink, title = title}
			end
			timer.Remove("SugarBoomCheck")
		end
	end
	
	
	
	local httpTbl = {
		//method = "POST",
		url = "",
		headers = {
			//["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36",
			//["X-Requested-With"] = "XMLHttpRequest",
			//["Origin"] = "https://www.youtube-audio.org",
			//["Referer"] = "https://www.youtube-audio.org/",
			//["Accept"] = "application/json",
			//["Host"] = "www.youtube-audio.org",
		},	
		type = "application/x-www-form-urlencoded",
		//body = "vidurl=https://www.youtube.com/watch?v="..url.."&quality=128",
		success = function(num,body,headers)
			local json = util.JSONToTable(body)
			if !json then
				chat.AddText(Color(255,255,255),sugar_boom.Lang["There was an error playing the video"])
				timer.Remove("SugarBoomCheck")
				return
			end
			
			if json and istable(json) and json["message"] and json["message"]:find("Invalid id") then
				print("Site doesn't allow that video ID")
				chat.AddText(Color(255,255,255),sugar_boom.Lang["There was an error playing the video"])
				timer.Remove("SugarBoomCheck")
				return
			end
			
			if !json["dlurl"] then
				return
			end
			
			if !isConverting and json["dlurl"] then
				isConverting = true
				Listen(json["dlurl"])
				chat.AddText(Color(255,255,255),sugar_boom.Lang["Link found, playing now!"])
				timer.Remove("SugarBoomCheck")
			end
		end,
	}
	
	if sugar_boom.Frm.SearchID == sugar_boom.Lang["View Favorites"] then
		local timesPlayed = sugar_boom.Favorites[url].timesPlayed
		self.Played:SetText(sugar_boom.Lang["Played"]..": "..(timesPlayed+1)..sugar_boom.Lang[" time(s)"])
	end
	
	http.Fetch("https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id="..url.."&key="..sugar_boom.APIKey,function(body,err)
		local vidLength = util.JSONToTable(body)
		local timeS = vidLength["items"][1]["contentDetails"]["duration"]
		local hasMin = timeS:find("M")

		if timeS:find("H") then 
			LocalPlayer():EmitSound("buttons/button11.wav")
			chat.AddText(Color(200,20,20),sugar_boom.Lang["You cannot play videos over 20 minutes!"])
			return 
		end
		
		if hasMin then
			local minTime = tonumber(string.sub(timeS,3,hasMin-1))
			if isnumber(minTime) and minTime > 20 then
				LocalPlayer():EmitSound("buttons/button11.wav")
				chat.AddText(Color(200,20,20),sugar_boom.Lang["You cannot play videos over 20 minutes!"])
				return 
			end
		end
		
		HTTP(httpTbl)
		chat.AddText(Color(255,255,255),sugar_boom.Lang["Converting video, please wait up to 30 seconds!"])
		timer.Create("SugarBoomCheck",20,1,function()
			HTTP(httpTbl)
		end)
	end)
end

function PANEL:OnMousePressed(key)
	local cSelf = self
	if sugar_boom.Frm.Cooldown > CurTime() then
		chat.AddText(Color(255,255,255),sugar_boom.Lang["Please wait "]..math.Round(sugar_boom.Frm.Cooldown - CurTime())..sugar_boom.Lang[" seconds before doing this!"])
		return
	end

	if key == MOUSE_LEFT and self.URL then
		sugar_boom.Frm.Cooldown = CurTime() + sugar_boom.Cooldown
		self:ListenToVideo(self.URL,self.Icon)
	elseif key == MOUSE_RIGHT and self.URL then
		local menu = vgui.Create("DMenu")
		menu:SetPos(gui.MousePos())
		local op = menu:AddOption(sugar_boom.Lang["Set on Repeat"],function()
			cSelf:ListenToVideo(cSelf.URL,cSelf.Icon,true)
		end)
		op:SetIcon("icon16/arrow_refresh.png")
		menu:MakePopup()
	end
end

vgui.Register("sugar_videopnl", PANEL, "DPanel")

local PANEL = {}

function PANEL:Init()

end

function PANEL:Paint(w,h)
    surface.SetDrawColor(whiteBar2)
	surface.DrawRect(w-1,0,1,h)
end

vgui.Register("sugar_boom_left",PANEL,"DScrollPanel")


local PANEL = {}

function PANEL:Init()
	self:SetText(sugar_boom.Lang["Search"])
	self:SetTextColor(Color(255,255,255,50))
	self.Did = false
	self:SetUpdateOnType(true)
end

function PANEL:Paint(w,h)
	
	surface.SetDrawColor(grey)
	surface.DrawRect(2,2,w-1,h-1)
	
	surface.SetDrawColor(whiteBar2)
	surface.DrawOutlinedRect(0,0,w,h)
	self:DrawTextEntryText(Color(255,255,255), Color(117, 117, 117), Color(255,255,255))
	self:SetFontInternal("boomFont_18")
end

function PANEL:OnFocusChanged(bool)
	if bool and !self.Did then
		self.Did = true
		self:SetText("")
		self:SetTextColor(Color(255,255,255))
	end
end

function PANEL:OnEnter()
	local id = sugar_boom.Frm.SearchID
	local searchTerm = self:GetValue()
	
	if id == sugar_boom.Lang["Search"] then
		return sugar_boom.Frm.Search:SearchVideo(newText)
	elseif id == sugar_boom.Lang["View Favorites"] then
		return sugar_boom.Frm.FavoritesPnl:PopulateFavorites(searchTerm)
	elseif id == sugar_boom.Lang["View History"] then
		return sugar_boom.Frm.HistoryPnl:PopulateHistory(searchTerm)
	end
end

function PANEL:OnValueChange(s)
	local id = sugar_boom.Frm.SearchID
	if id == sugar_boom.Lang["View Favorites"] then
		return sugar_boom.Frm.FavoritesPnl:PopulateFavorites(s)
	elseif id == sugar_boom.Lang["View History"] then
		return sugar_boom.Frm.HistoryPnl:PopulateHistory(s)
	end
end

vgui.Register("sugar_vid_search",PANEL,"DTextEntry")


local PANEL = {}

function PANEL:Init()
	function self.Slider:Paint(w,h)
		surface.SetDrawColor(whiteBar2)
		surface.DrawRect(0,0,w,2)
		local pos = self.Knob:GetPos()
		
		draw.SimpleTextOutlined(math.Round(pos/self:GetWide()),"Default",w,8,Color(255,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER,1,Color(33,33,33))
	end
	
	self.Slider.Knob:SetSize(2,15)
	
	function self.Slider.Knob:Paint(w,h)
		if self:IsHovered() then
				surface.SetDrawColor(Color(20, 200, 20))
		else
			surface.SetDrawColor(Color(177,177,177))
		end
		surface.DrawRect(0, -8 ,w,h)
	end
	
	self:SetMin(0)
	self:SetMax(1)
	self:SetDecimals(1)
	self.TextArea:SetVisible(false)
end

function PANEL:OnValueChanged(val)
	if !IsValid(self.VolumeText) then return end
	if isnumber(val) then
		sugar_boom.VolumeControl = val
		self.VolumeText:SetText(math.Round(val*100).."%")
	end
end

function PANEL:Paint(w,h)

end

vgui.Register("sugar_boom_volume",PANEL,"DNumSlider")

local PANEL = {}

function PANEL:Init()
	self.URL = nil
	self.Icon = nil
	self.Title = nil
	self:SetToolTip(sugar_boom.Lang["Add to favorites"])
end

function PANEL:SetVideoData(url,icon,title)
	self.URL = url
	self.Icon = icon
	self.Title = title
end

function PANEL:Paint(w,h)
	local hovered = self:IsHovered()
	if sugar_boom.Favorites[self.URL] == nil and !hovered then
		surface.SetDrawColor(grey)     
	elseif sugar_boom.Favorites[self.URL] or hovered then
		surface.SetDrawColor(white)
	end
	surface.SetMaterial(favoriteMat)
	surface.DrawTexturedRect(0,0,w,h)
end

function PANEL:DoClick()
	 if !sugar_boom.Favorites[self.URL] then
		local favTbl = {
			id = self.URL,
			thumbnail = self.Icon,
			title = self.Title,
		}
		sugar_boom:AddFavorite(favTbl)    
		sugar_boom.Frm:AddToCategory(favTbl,sugar_boom.Lang["Favorites"])
		LocalPlayer():EmitSound("garrysmod/ui_click.wav")
		chat.AddText(Color(255,255,255),self.Title..sugar_boom.Lang[" was "],Color(27,94,32),sugar_boom.Lang["added"],Color(255,255,255),sugar_boom.Lang[" to your favorites!"])
	elseif sugar_boom.Favorites[self.URL] then
		sugar_boom:RemoveFavorite(self.URL)
		if sugar_boom.Frm.SearchID == sugar_boom.Lang["View Favorites"] then
			sugar_boom.Frm.FavoritesPnl:PopulateFavorites()
		end
		LocalPlayer():EmitSound("garrysmod/ui_return.wav")
		chat.AddText(Color(255,255,255),self.Title..sugar_boom.Lang[" was "],Color(200,20,20),sugar_boom.Lang["removed"],Color(255,255,255),sugar_boom.Lang[" to your favorites!"])
	end
end

vgui.Register("sugar_boom_favorite",PANEL,"DButton")