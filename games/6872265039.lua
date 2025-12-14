--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local sessioninfo = vape.Libraries.sessioninfo
local bedwars = {}

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
	local function dumpRemote(tab)
		local ind = table.find(tab, 'Client')
		return ind and tab[ind + 1] or ''
	end

	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function() return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9) end)
		if KnitInit then break end
		task.wait()
	until KnitInit
	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end
	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client

	bedwars = setmetatable({
		Client = Client,
		CrateItemMeta = debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3),
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	vape:Clean(function()
		table.clear(bedwars)
	end)
end)

for _, v in vape.Modules do
	if v.Category == 'Combat' or v.Category == 'Minigames' then
		vape:Remove(i)
	end
end

run(function()
	local Sprint
	local old
	
	Sprint = vape.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = false end) end
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					bedwars.SprintController:startSprinting()
					return call
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() bedwars.SprintController:stopSprinting() end))
				bedwars.SprintController:stopSprinting()
			else
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = true end) end
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.'
	})
end)
	
run(function()
	local AutoGamble
	
	AutoGamble = vape.Categories.Minigames:CreateModule({
		Name = 'AutoGamble',
		Function = function(callback)
			if callback then
				AutoGamble:Clean(bedwars.Client:GetNamespace('RewardCrate'):Get('CrateOpened'):Connect(function(data)
					if data.openingPlayer == lplr then
						local tab = bedwars.CrateItemMeta[data.reward.itemType] or {displayName = data.reward.itemType or 'unknown'}
						notif('AutoGamble', 'Won '..tab.displayName, 5)
					end
				end))
	
				repeat
					if not bedwars.CrateAltarController.activeCrates[1] then
						for _, v in bedwars.Store:getState().Consumable.inventory do
							if v.consumable:find('crate') then
								bedwars.CrateAltarController:pickCrate(v.consumable, 1)
								task.wait(1.2)
								if bedwars.CrateAltarController.activeCrates[1] and bedwars.CrateAltarController.activeCrates[1][2] then
									bedwars.Client:GetNamespace('RewardCrate'):Get('OpenRewardCrate'):SendToServer({
										crateId = bedwars.CrateAltarController.activeCrates[1][2].attributes.crateId
									})
								end
								break
							end
						end
					end
					task.wait(1)
				until not AutoGamble.Enabled
			end
		end,
		Tooltip = 'Automatically opens lucky crates, piston inspired!'
	})
end)
	
run(function()
    local ok, err = pcall(function()
        repeat task.wait() until vape and vape.Categories and vape.Categories.Render
        local ClanModule
        local ClanColor = Color3.new(1, 1, 1)
        local enabledFlag = false
        local EquippedTag = nil
    
        local SavedTags = {}
        local TagToggles = {}
        
        local function safeSet(attr, value)
            local lp = game.Players.LocalPlayer
            if lp and lp.SetAttribute then
                pcall(function()
                    lp:SetAttribute(attr, value)
                end)
            end
        end
        
        local function buildTag()
            if not EquippedTag then return "" end
            local hex = string.format("#%02X%02X%02X",
                ClanColor.R * 255,
                ClanColor.G * 255,
                ClanColor.B * 255
            )
            return "<font color='"..hex.."'>"..EquippedTag.."</font>"
        end
        
        local function updateClanTag()
            if enabledFlag then
                safeSet("ClanTag", buildTag())
            else
                safeSet("ClanTag", "")
            end
        end
        
        local function createTagToggles()
            for i, toggle in pairs(TagToggles) do
                if toggle and toggle.Object then
                    toggle.Object:Remove()
                end
            end
            TagToggles = {}
            
            for i, tag in ipairs(SavedTags) do
                if tag and tag ~= "" then
                    TagToggles[i] = ClanModule:CreateToggle({
                        Name = tag,
                        Function = function(callback)
                            if callback then
                                EquippedTag = tag
                                for j, otherToggle in pairs(TagToggles) do
                                    if j ~= i and otherToggle and otherToggle.Enabled then
                                        otherToggle:Toggle()
                                    end
                                end
                            else
                                if EquippedTag == tag then
                                    EquippedTag = nil
                                end
                            end
                            updateClanTag()
                        end
                    })
                end
            end
        end
        
        ClanModule = vape.Categories.Render:CreateModule({
            Name = "CustomClanTag",
            HoverText = "Click tags to equip/unequip",
            Function = function(state)
                enabledFlag = state
                if state then
                    createTagToggles()
                end
                updateClanTag()
            end
        })
        
        ClanModule:CreateColorSlider({
            Name = "Tag Color",
            Function = function(h, s, v)
                ClanColor = Color3.fromHSV(h, s, v)
                updateClanTag()
            end
        })
        
        local tagListObject = ClanModule:CreateTextList({
            Name = "Clan Tags",
            Placeholder = "Add tags here",
            Function = function(list)
                SavedTags = {}
                for i, tag in ipairs(list) do
                    if tag and tag ~= "" then
                        table.insert(SavedTags, tag)
                    end
                end
                
                createTagToggles()
            end
        })
        
    end)
    if not ok then
        warn("CustomClanTag error:", err)
    end
end)

run(function()
	local FalseBan
	local PlayerDropdown
	local InvisibleCharacters = {}
	local CharacterConnections = {}
	
	local function makeCharacterInvisible(character, player)
		if InvisibleCharacters[character] then return end
		
		local parts = {}
		local accessories = {}
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				parts[part] = {
					Transparency = part.Transparency,
					CanCollide = part.CanCollide,
					CastShadow = part.CastShadow
				}
				part.Transparency = 1
				part.CanCollide = false
				part.CastShadow = false
			elseif part:IsA("Decal") or part:IsA("Texture") then
				parts[part] = {Transparency = part.Transparency}
				part.Transparency = 1
			elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
				parts[part] = {Enabled = part.Enabled}
				part.Enabled = false
			elseif part:IsA("Accessory") then
				accessories[part] = {
					Accessory = part,
					Parent = part.Parent
				}
				part.Parent = nil
			end
		end
		
		if humanoid and humanoid.RootPart then
			parts[humanoid.RootPart] = parts[humanoid.RootPart] or {}
			parts[humanoid.RootPart].Transparency = 1
			humanoid.RootPart.Transparency = 1
			humanoid.RootPart.CanCollide = false
		end
		
		InvisibleCharacters[character] = {
			Parts = parts,
			Accessories = accessories,
			Player = player,
			Connections = {}
		}
		
		local connections = InvisibleCharacters[character].Connections
		
		table.insert(connections, character.DescendantAdded:Connect(function(descendant)
			task.wait()
			if FalseBan.Enabled and InvisibleCharacters[character] then
				if descendant:IsA("BasePart") then
					descendant.Transparency = 1
					descendant.CanCollide = false
					descendant.CastShadow = false
				elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
					descendant.Transparency = 1
				elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
					descendant.Enabled = false
				elseif descendant:IsA("Accessory") then
					local data = {
						Accessory = descendant,
						Parent = descendant.Parent
					}
					InvisibleCharacters[character].Accessories[descendant] = data
					descendant.Parent = nil
				end
			end
		end))
		
		table.insert(connections, character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				restoreCharacterVisibility(character)
			end
		end))
		
		if humanoid then
			table.insert(connections, humanoid.Died:Connect(function()
				task.wait(2)
				restoreCharacterVisibility(character)
			end))
		end
	end
	
	local function restoreCharacterVisibility(character)
		if not InvisibleCharacters[character] then return end
		
		local data = InvisibleCharacters[character]
		
		for part, properties in data.Parts do
			if part and part.Parent then
				if part:IsA("BasePart") then
					part.Transparency = properties.Transparency or 0
					part.CanCollide = properties.CanCollide ~= nil and properties.CanCollide or true
					part.CastShadow = properties.CastShadow ~= nil and properties.CastShadow or true
				elseif part:IsA("Decal") or part:IsA("Texture") then
					part.Transparency = properties.Transparency or 0
				elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
					part.Enabled = properties.Enabled ~= nil and properties.Enabled or true
				end
			end
		end
		
		for accessory, accessoryData in data.Accessories do
			if accessory and accessoryData.Parent then
				accessory.Parent = accessoryData.Parent
			end
		end
		
		for _, connection in data.Connections do
			pcall(function()
				connection:Disconnect()
			end)
		end
		
		InvisibleCharacters[character] = nil
	end
	
	local function getPlayerList()
		local playerList = {}
		
		for _, player in playersService:GetPlayers() do
			if player ~= lplr then
				table.insert(playerList, player.Name)
			end
		end
		
		table.sort(playerList)
		return playerList
	end
	
	local function setupPlayerConnections(player)
		if CharacterConnections[player] then return end
		
		local connections = {}
		
		table.insert(connections, player.CharacterAdded:Connect(function(character)
			task.wait(0.5)
			if FalseBan.Enabled and PlayerDropdown.Value == player.Name then
				makeCharacterInvisible(character, player)
			end
		end))
		
		table.insert(connections, player.CharacterRemoving:Connect(function(character)
			restoreCharacterVisibility(character)
		end))
		
		CharacterConnections[player] = connections
	end
	
	local function processSelectedPlayer()
		if PlayerDropdown.Value and PlayerDropdown.Value ~= "" then
			local player = playersService:FindFirstChild(PlayerDropdown.Value)
			if player and player.Character then
				makeCharacterInvisible(player.Character, player)
			end
		end
	end
	
	FalseBan = vape.Categories.Render:CreateModule({
		Name = 'FalseBan',
		Function = function(callback)
			if callback then
				for _, player in playersService:GetPlayers() do
					if player ~= lplr then
						setupPlayerConnections(player)
					end
				end
				
				FalseBan:Clean(playersService.PlayerAdded:Connect(function(player)
					if player == lplr then return end
					
					setupPlayerConnections(player)
					
					if player.Character and FalseBan.Enabled and PlayerDropdown.Value == player.Name then
						task.wait(0.5)
						makeCharacterInvisible(player.Character, player)
					end
				end))
				
				FalseBan:Clean(playersService.PlayerRemoving:Connect(function(player)
					if CharacterConnections[player] then
						for _, connection in CharacterConnections[player] do
							pcall(function()
								connection:Disconnect()
							end)
						end
						CharacterConnections[player] = nil
					end
					
					if player.Character then
						restoreCharacterVisibility(player.Character)
					end
				end))
				
				processSelectedPlayer()
				
			else
				for character, _ in InvisibleCharacters do
					restoreCharacterVisibility(character)
				end
				table.clear(InvisibleCharacters)
				
				for player, connections in CharacterConnections do
					for _, connection in connections do
						pcall(function()
							connection:Disconnect()
						end)
					end
				end
				table.clear(CharacterConnections)
			end
		end,
		Tooltip = 'Select a player to make invisible client-side only.'
	})
	
	PlayerDropdown = FalseBan:CreateDropdown({
		Name = 'Select Player',
		List = getPlayerList(),
		Function = function(val)
			if FalseBan.Enabled then
				FalseBan:Toggle()
				FalseBan:Toggle()
			end
		end
	})
end)
