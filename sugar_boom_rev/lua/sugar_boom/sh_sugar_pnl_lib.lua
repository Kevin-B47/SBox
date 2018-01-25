if CLIENT then
	
	local sugarHeights = {}
	local sugarWidths = {}
	
	function ClearConvertCache()
		sugarHeights = {}
		sugarWidths = {}
	end

	local fitW = 1920
	local fitH = 1080

	local pnl = FindMetaTable("Panel")

	function pnl:GetTextSizeFix() -- Default pnl:GetTextSize seems to be broken? I did not make this
		surface.SetFont(self:GetFont())
		local w, h = surface.GetTextSize(self:GetText())
		return w, h
	end
	
	function GetSugarTextSize(txt,font)
		surface.SetFont(font)
		local w, h = surface.GetTextSize(txt)
		return w, h
	end
	
	function pnl:SetSugarSize(w,h) -- Took hours to make the first verision compatible with all resolutions, this is super easy
		self:SetSize(ScrW() / fitW * w, ScrH() / fitH * h)
	end
	
	function pnl:SetSugarPos(w,h)
		self:SetPos(ScrW() / fitW * w, ScrH() / fitH * h)
	end
	
	function SugarConvertWidth(w)
		if sugarWidths[w] then
			return sugarWidths[w]
		end
		
		sugarWidths[w] = ScrW() / fitW * w
		return sugarWidths[w]
	end
	
	function SugarConvertHeight(h)
		if sugarHeights[h] then
			return sugarHeights[h]
		end
		
		sugarHeights[h] = ScrH() / fitH * h
		return sugarHeights[h]
	end
	
	function SugarLerpColor(time,color,toColor)
		color.r = Lerp(time, color.r, toColor.r)
		color.g = Lerp(time, color.g, toColor.g)
		color.b = Lerp(time,color.b,toColor.b)
		color.a = Lerp(time,color.a,toColor.a) or 255
		return color
	end
	
	function FormatNumber(number)
		if not number then return "" end
		if number >= 1e14 then return tostring(number) end
		number = tostring(number)
		local sep = sep or ","
		local dp = string.find(number, "%.") or #number + 1

		for i = dp - 4, 1, -3 do
			number = number:sub(1, i) .. sep .. number:sub(i + 1)
		end

		return number
	end
	
end