-- Delete unwanted items
local _, ns = ...

local idwt = CreateFrame("Frame", "IDWT", UIParent)
local idwt_timer = {}
local usingDefaultBags = false
local markCounter = 1
local countLimit = 1

-- For debug
local function dbgPrint(message)
    print(message)
    local index = GetChannelName("DefDebug")
    if (index~=nil) then
        --SendChatMessage(message , "CHANNEL", nil, index);
    end
end

-- TODO: BUG every time you do not have a item to delete in inventory and you are changing items -> peddler and idwt eats cpu time
--       FIXED, but only idwt not peddler

-- Events
idwt:RegisterEvent("PLAYER_ENTERING_WORLD")
idwt:RegisterEvent("ADDON_LOADED")
idwt:RegisterEvent("MERCHANT_SHOW")

local function itemIsToBeDeleted(itemID, uniqueItemID)
    local _, link, quality, itemLevel, _, itemType, subType, _, equipSlot, _, price = GetItemInfo(itemID)

    -- Has price?  Sale IT!
    if price > 0 then
        return
    end

    return ItemsToDelete[uniqueItemID]
end

local function showCoinTexture(itemButton)
    if not itemButton.coins_delete then
        local texture = itemButton:CreateTexture(nil, "OVERLAY")
        texture:SetTexture("Interface\\AddOns\\IDontWantThat\\coins_delete")

        -- Default padding for making bottom-right look great.
        local paddingX, paddingY = -3, 1
        if string.find(IconPlacement, "TOP") then
            paddingY = -3
        end
        if string.find(IconPlacement, "LEFT") then
            paddingX = 1
        end

        texture:SetPoint(IconPlacement, paddingX, paddingY)

        itemButton.coins_delete = texture
    end

    itemButton.coins_delete:Show()


    if not usingDefaultBags then
        idwt:SetScript("OnUpdate", nil)
    end
    markCounter = 0

    if usingDefaultBags or IsAddOnLoaded("Baggins") or IsAddOnLoaded("AdiBags") then
        -- Baggins/AdiBag update slower than the others, so we have to account for that.
        -- Default WoW bags need to constantly be updating, due to opening of individual bags.
        countLimit = 30
    else
        countLimit = 5
    end
end

-- Serves to get the item's itemID + suffixID.
local function getUniqueItemID(bagNumber, slotNumber)
    local itemString = GetContainerItemLink(bagNumber, slotNumber)
    if not itemString then
        return
    end

    local _, itemID, _, _, _, _, _, suffixID = strsplit(":", itemString)
    itemID = tonumber(itemID)
    suffixID = tonumber(suffixID)

    if not itemID then
        return
    end

    local uniqueItemID = itemID
    if suffixID and suffixID ~= 0 then
        uniqueItemID = itemID .. suffixID
    end

    return itemID, uniqueItemID
end

local function checkItem(bagNumber, slotNumber, itemButton)
    local itemID, uniqueItemID = getUniqueItemID(bagNumber, slotNumber)

    if uniqueItemID then
        if itemIsToBeDeleted(itemID, uniqueItemID) then
            showCoinTexture(itemButton)
        elseif itemButton.coins_delete then
            itemButton.coins_delete:Hide()
        end
    elseif itemButton.coins_delete then
        itemButton.coins_delete:Hide()
    end
end

--  __  __            _      ____
-- |  \/  |          | |    |  _ \
-- | \  / | __ _ _ __| | __ | |_) | __ _  __ _ ___
-- | |\/| |/ _` | '__| |/ / |  _ < / _` |/ _` / __|
-- | |  | | (_| | |  |   <  | |_) | (_| | (_| \__ \
-- |_|  |_|\__,_|_|  |_|\_\ |____/ \__,_|\__, |___/
--                                        __/ |
--                                       |___/
local function markBagginsBags()
    for bagid, bag in ipairs(Baggins.bagframes) do
        for sectionid, section in ipairs(bag.sections) do
            for buttonid, itemButton in ipairs(section.items) do
                local itemsBagNumber = itemButton:GetParent():GetID()
                local itemsSlotNumber = itemButton:GetID()

                checkItem(itemsBagNumber, itemsSlotNumber, itemButton)
            end
        end
    end
end

-- Also works for Bagnon.
local function markCombuctorBags()
    for bagNumber = 0, 4 do
        for slotNumber = 1, 36 do
            local itemButton = _G["ContainerFrame" .. bagNumber + 1 .. "Item" .. slotNumber]

            local itemButtonParent = itemButton:GetParent()
            if itemButtonParent then
                local itemsBagNumber = itemButtonParent:GetID()
                local itemsSlotNumber = itemButton:GetID()
                checkItem(itemsBagNumber, itemsSlotNumber, itemButton)
            end
        end
    end
end

local function markOneBagBags()
    for bagNumber = 0, 4 do
        local bagsSlotCount = GetContainerNumSlots(bagNumber)
        for slotNumber = 1, bagsSlotCount do
            local itemButton = _G["OneBagFrameBag" .. bagNumber .. "Item" .. bagsSlotCount - slotNumber + 1]

            if itemButton then
                local itemsBagNumber = itemButton:GetParent():GetID()
                local itemsSlotNumber = itemButton:GetID()
                checkItem(itemsBagNumber, itemsSlotNumber, itemButton)
            end
        end
    end
end

local function markBaudBagBags()
    for bagNumber = 0, 4 do
        local bagsSlotCount = GetContainerNumSlots(bagNumber)
        for slotNumber = 1, bagsSlotCount do
            local itemButton = _G["BaudBagSubBag" .. bagNumber .. "Item" .. slotNumber]
            checkItem(bagNumber, slotNumber, itemButton)
        end
    end
end

local function markAdiBagBags()
    local totalSlotCount = 0
    for bagNumber = 0, 4 do
        totalSlotCount = totalSlotCount + GetContainerNumSlots(bagNumber)
    end

    -- For some reason, AdiBags can have way more buttons than the actual amount of bag slots... not sure how or why.
    totalSlotCount = totalSlotCount + 60

    if totalSlotCount < 100 then
        totalSlotCount = 100
    end

    for slotNumber = 1, totalSlotCount do
        local itemButton = _G["AdiBagsItemButton" .. slotNumber]
        if itemButton then
            local _, bag, slot = strsplit('-', tostring(itemButton))

            bag = tonumber(bag)
            slot = tonumber(slot)

            if bag and slot then
                checkItem(bag, slot, itemButton)
            end
        end
    end
end

local function markArkInventoryBags()
    for bagNumber = 0, 4 do
        local bagsSlotCount = GetContainerNumSlots(bagNumber)
        for slotNumber = 1, bagsSlotCount do
            local itemButton = _G["ARKINV_Frame1ScrollContainerBag" .. bagNumber + 1 .. "Item" .. slotNumber]
            checkItem(bagNumber, slotNumber, itemButton)
        end
    end
end

local function markCargBagsNivayaBags()
    local totalSlotCount = 0
    for bagNumber = 0, 4 do
        totalSlotCount = totalSlotCount + GetContainerNumSlots(bagNumber)
    end

    -- Somehow, Nivaya can have higher slot-numbers than actual bag slots exist...
    totalSlotCount = totalSlotCount * 2

    for slotNumber = 1, totalSlotCount do
        local itemButton = _G["NivayaSlot" .. slotNumber]
        if itemButton then
            local itemsBag = itemButton:GetParent()

            if itemsBag then
                local itemsBagNumber = itemsBag:GetID()
                local itemsSlotNumber = itemButton:GetID()
                checkItem(itemsBagNumber, itemsSlotNumber, itemButton)
            end
        end
        slotNumber = slotNumber + 1
    end
end

local function markMonoBags()
    local totalSlotCount = 0
    for bagNumber = 0, 4 do
        totalSlotCount = totalSlotCount + GetContainerNumSlots(bagNumber)
    end

    for slotNumber = 1, totalSlotCount do
        local itemButton = _G["m_BagsSlot" .. slotNumber]
        if itemButton then
            local itemsBagNumber = itemButton:GetParent():GetID()
            local itemsSlotNumber = itemButton:GetID()
            checkItem(itemsBagNumber, itemsSlotNumber, itemButton)
        end
        slotNumber = slotNumber + 1
    end
end

local function markDerpyBags()
    for bagNumber = 0, 4 do
        local bagsSlotCount = GetContainerNumSlots(bagNumber)
        for slotNumber = 1, bagsSlotCount do
            local itemButton = _G["StuffingBag" .. bagNumber .. "_" .. slotNumber]
            checkItem(bagNumber, slotNumber, itemButton)
        end
    end
end

local function markElvUIBags()
    for bagNumber = 0, 4 do
        local bagsSlotCount = GetContainerNumSlots(bagNumber)
        for slotNumber = 1, bagsSlotCount do
            local itemButton = _G["ElvUI_ContainerFrameBag" .. bagNumber .. "Slot" .. slotNumber]
            checkItem(bagNumber, slotNumber, itemButton)
        end
    end
end

local function markInventorianBags()
    for bagNumber = 0, NUM_CONTAINER_FRAMES do
        for slotNumber = 1, 36 do
            local itemButton = _G["ContainerFrame" .. bagNumber + 1 .. "Item" .. slotNumber]

            if itemButton then
                local itemButtonParent = itemButton:GetParent()
                if itemButtonParent then
                    local itemsBagNumber = itemButtonParent:GetID()
                    local itemsSlotNumber = itemButton:GetID()
                    checkItem(itemsBagNumber, itemsSlotNumber, itemButton)
                end
            end
        end
    end
end

-- Special thanks to Xodiv of Curse for this one!
local function markLiteBagBags()
    for i = 1, LiteBagInventory.size do
        local button = LiteBagInventory.itemButtons[i]
        local itemsBagNumber = button:GetParent():GetID()
        local itemsSlotNumber = button:GetID()
        checkItem(itemsBagNumber, itemsSlotNumber, button)
    end
end

-- Special thanks to Tymesink from WowInterface for this one.
local function markfamBagsBags()
    for bagNumber = 0, 4 do
        local bagsSlotCount = GetContainerNumSlots(bagNumber)
        for slotNumber = 1, bagsSlotCount do
            local itemButton = _G["famBagsButton_" .. bagNumber .. "_" .. slotNumber]
            checkItem(bagNumber, slotNumber, itemButton)
        end
    end
end

-- Also works for bBag.
local function markNormalBags()
    for containerNumber = 0, 4 do
        local container = _G["ContainerFrame" .. containerNumber + 1]
        if (container:IsShown()) then
            local bagsSlotCount = GetContainerNumSlots(containerNumber)
            for slotNumber = 1, bagsSlotCount do
                -- It appears there are two ways of finding items!
                --   Accessing via _G means that bagNumbers are 1-based indices and
                --   slot numbers start from the bottom-right rather than top-left!
                -- Additionally, as only a couple of the bags may be visible at any
                --   given time, we may be looking at items whose buttons don't
                --   currently exist, and mark the wrong ones, so get the actual
                --   bag & slot number from the itemButton.

                local itemButton = _G["ContainerFrame" .. containerNumber + 1 .. "Item" .. bagsSlotCount - slotNumber + 1]

                local bagNumber = itemButton:GetParent():GetID()
                local actualSlotNumber = itemButton:GetID()
                checkItem(bagNumber, actualSlotNumber, itemButton)
            end
        end
    end
end

local function markWares()
    if IsAddOnLoaded("Baggins") then
        markBagginsBags()
    elseif IsAddOnLoaded("Combuctor") or IsAddOnLoaded("Bagnon") then
        markCombuctorBags()
    elseif IsAddOnLoaded("OneBag3") then
        markOneBagBags()
    elseif IsAddOnLoaded("BaudBag") then
        markBaudBagBags()
    elseif IsAddOnLoaded("AdiBags") then
        markAdiBagBags()
    elseif IsAddOnLoaded("ArkInventory") then
        markArkInventoryBags()
    elseif IsAddOnLoaded("famBags") then
        markfamBagsBags()
    elseif IsAddOnLoaded("cargBags_Nivaya") then
        markCargBagsNivayaBags()
    elseif IsAddOnLoaded("m_Bags") then
        markMonoBags()
    elseif IsAddOnLoaded("DerpyStuffing") then
        markDerpyBags()
    elseif IsAddOnLoaded("ElvUI") and _G["ElvUI_ContainerFrame"] then
        markElvUIBags()
    elseif IsAddOnLoaded("Inventorian") then
        markInventorianBags()
    elseif IsAddOnLoaded("LiteBag") then
        markLiteBagBags()
    else
        usingDefaultBags = true
        markNormalBags()
    end
    -- Just update once
    if not usingDefaultBags then
        idwt:SetScript("OnUpdate", nil)
    end
    markCounter = 0
end

ns.markWares = markWares

-- END MARK BAGS

local function onUpdate()
    --dbgPrint("Counter: "..markCounter.." / Limit: "..countLimit)
    markCounter = markCounter + 1
    if markCounter <= countLimit then
        return
    else
        markCounter = 0
        markWares()
    end
end

local function handleBagginsOpened()
    if markCounter == 0 then
        idwt:SetScript("OnUpdate", onUpdate)
    end
end

--- Checks if there is a unwanted item present
--  TODO: maybe use a table so it does not have to iterate 2 times over bagslots
local function isUnwantedItemPresent()
    for bagNumber = 0, 4 do
        local bagsSlotCount = GetContainerNumSlots(bagNumber)
        for slotNumber = 1, bagsSlotCount do
            local itemID, uniqueItemID = getUniqueItemID(bagNumber, slotNumber)

            if uniqueItemID and itemIsToBeDeleted(itemID, uniqueItemID) then
                return true
            end
        end
    end
    return false
end

local function deleteUnwantedItems()
    for bagNumber = 0, 4 do
        local bagsSlotCount = GetContainerNumSlots(bagNumber)
        for slotNumber = 1, bagsSlotCount do
            local itemID, uniqueItemID = getUniqueItemID(bagNumber, slotNumber)

            if uniqueItemID and itemIsToBeDeleted(itemID, uniqueItemID) then
                local itemButton = _G["ContainerFrame" .. bagNumber + 1 .. "Item" .. bagsSlotCount - slotNumber + 1]

                if itemButton.coins_delete then
                    itemButton.coins_delete:Hide()
                end

                local name, _, quality, _, _, _, _, _, _, _, _ = GetItemInfo(itemID)

                -- Only print when not 'silenced'
                if not idwtOptions.silence then
                    print("Deleting: "..name)
                end

                PickupContainerItem(bagNumber, slotNumber)
                DeleteCursorItem()

            end
        end
    end
end

-- Create Confirm Popup
StaticPopupDialogs["IDWT_DeleteUnwantedItems"] = {
    text = "Sure you want to delete unwanted items?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        deleteUnwantedItems()
    end,
    timeout = 5,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function handleEvent(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "IDontWantThat" then
        idwt:UnregisterEvent("ADDON_LOADED")

        if not ItemsToDelete then
            ItemsToDelete = {}
        end

        if not ModifierKey then
            ModifierKey = "CTRL"
        end

        if not IconPlacement then
            IconPlacement = "BOTTOMRIGHT"
        end

        if not idwtOptions then
            idwtOptions = {
                silence = false,
                confirm = true,
                merchant = true,
            }
        end

        countLimit = 400
        idwt:SetScript("OnUpdate", onUpdate)

        if IsAddOnLoaded("Baggins") then
            Baggins:RegisterSignal("Baggins_BagOpened", handleBagginsOpened, Baggins)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        idwt:RegisterEvent("BAG_UPDATE")
    elseif event == "BAG_UPDATE" then
        if markCounter == 0 then
            idwt:SetScript("OnUpdate", onUpdate)
        end
        --dbgPrint("BAG_UPDATE")
    elseif event == "MERCHANT_SHOW" then
        -- Stop if options forbids to delete on merchant popup
        if not idwtOptions.merchant then return end
        -- Call a popup if user is sure to delete
        if idwtOptions.confirm and isUnwantedItemPresent() then
            StaticPopup_Show("IDWT_DeleteUnwantedItems")
        else
            deleteUnwantedItems()
        end
    end
end

idwt:SetScript("OnEvent", handleEvent)

local function handleItemClick(self, button)
    local modifierDown = (ModifierKey == 'CTRL' and IsControlKeyDown() or (ModifierKey == 'SHIFT' and IsShiftKeyDown() or (ModifierKey == 'ALT' and IsAltKeyDown())))
    local usingidwt = modifierDown and button == 'RightButton'
    if not usingidwt then
        return
    end

    local bagNumber = self:GetParent():GetID()
    local slotNumber = self:GetID()

    local itemID, uniqueItemID = getUniqueItemID(bagNumber, slotNumber)

    -- Empty bag slots cannot be sold, silly!
    if not itemID then
        return
    end

    local _, link, quality, _, _, itemType, subType, _, equipSlot, _, price = GetItemInfo(itemID)
    if not price or price > 0 then
        return
    end

    if ItemsToDelete[uniqueItemID] then
        ItemsToDelete[uniqueItemID] = nil
    else
        ItemsToDelete[uniqueItemID] = 1
    end

    markWares()
end

hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", handleItemClick)

-- Add slash commands for options
local function addSlashCommand(name, func, ...)
    SlashCmdList[name] = func
    local command = ''
    for i = 1, select('#', ...) do
        command = select(i, ...)
        if strsub(command, 1, 1) ~= '/' then
            command = '/' .. command
        end
        _G['SLASH_'..name..i] = command
    end
end

-- Handling of slash command
addSlashCommand("idwt", function(command)
    if command == "" then
        print("Options for - I Dont Want That -")
        local confirm, silence, merchant
        if idwtOptions.confirm then confirm = "|cff00FF00 confirm |cffFFFFFF" else confirm = "|cffFF0011 confirm |cffFFFFFF" end
        print("/idwt"..confirm .."- Toggle the confirm popup |cffFF0011 - BE CAREFUL WITH IT !")
        if idwtOptions.silence then silence = "|cff00FF00 silence |cffFFFFFF" else silence = "|cffFF0011 silence |cffFFFFFF" end
        print("/idwt"..silence.."- Toggle the chat output of deleted items.")
        if idwtOptions.merchant then merchant = "|cff00FF00 merchant |cffFFFFFF" else merchant = "|cffFF0011 merchant |cffFFFFFF" end
        print("/idwt"..merchant.."- Toggles if deleting should happen when you talk to a merchant.")
        print("/idwt delete  - Deletes unwanted items.")
    elseif command == "confirm" then
        if idwtOptions.confirm == true then
            idwtOptions.confirm = false
            print("I Dont Want That confirm: - |cffFF0011 INACTIVE")
        elseif idwtOptions.confirm == false then
            idwtOptions.confirm = true
            print("I Dont Want That confirm: - |cff00FF00 ACTIVE")
        end
    elseif command == "silence" then
        if idwtOptions.silence == true then
            idwtOptions.silence = false
            print("I Dont Want That silence: - |cffFF0011 INACTIVE")
        elseif idwtOptions.silence == false then
            idwtOptions.silence = true
            print("I Dont Want That silence: - |cff00FF00 ACTIVE")
        end
    elseif command == "delete" then
        if idwtOptions.confirm and isUnwantedItemPresent() then
            StaticPopup_Show ("IDWT_DeleteUnwantedItems")
        else
            deleteUnwantedItems()
        end
    elseif  command == "merchant" then
        if idwtOptions.merchant == true then
            idwtOptions.merchant = false
            print("I Dont Want That: merchant - |cffFF0011 INACTIVE")
        elseif idwtOptions.merchant == false then
            idwtOptions.merchant = true
            print("I Dont Want That: merchant - |cff00FF00 ACTIVE")
        end
    else
        print("Command: "..command.." not found.")
    end
end, "idwt")