-- AddonOptions/FluxOptionsChat.lua
-- Show or hide buttons on the chat column. Stored in FluxOptions.db.global.chatCopyPaste.

local addonName = ...

local function GetCCPDB()
    if FluxOptions and FluxOptions.db and FluxOptions.db.global then
        return FluxOptions.db.global.chatCopyPaste
    end
    return nil
end

local function NotifyAndRefresh()
    if FluxCCP and FluxCCP.UpdateColumnButtons then
        FluxCCP:UpdateColumnButtons()
    end
    if _G.FluxChatFrame_RefreshSocialLayout then
        FluxChatFrame_RefreshSocialLayout()
    end
    local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if ACR then
        ACR:NotifyChange("FluxUI")
    end
end

local function ButtonToggle(key, name, desc, order, exists)
    return {
        type = "toggle",
        name = name,
        desc = desc,
        order = order,
        width = "full",
        hidden = function()
            return not exists()
        end,
        get = function()
            local db = GetCCPDB()
            return not db or db[key] ~= false
        end,
        set = function(_, val)
            local db = GetCCPDB()
            if not db then
                return
            end
            db[key] = val and true or false
            NotifyAndRefresh()
        end,
    }
end

local function BuildChatOptions()
    return {
        name = "Chat",
        type = "group",
        order = 49,
        args = {
            intro = {
                type = "description",
                name = "Show or hide buttons on the chat column. Hiding FluxUI Options only removes the gear on chat. /fluxui still opens this window, and the MicroMenu tab can show that gear on the micro bar.\n",
                order = 0,
                fontSize = "medium",
                width = "full",
            },
            chat_btn_social = ButtonToggle(
                "chat_btn_social",
                "Social",
                "Friends / quick join button above the chat column.",
                10,
                function()
                    return _G.QuickJoinToastButton ~= nil or _G.FriendsMicroButton ~= nil
                end
            ),
            chat_btn_channel = ButtonToggle(
                "chat_btn_channel",
                "Channels",
                "Chat channel button.",
                20,
                function()
                    return _G.ChatFrameChannelButton ~= nil
                end
            ),
            chat_btn_guild = ButtonToggle(
                "chat_btn_guild",
                "Guild",
                "Opens the guild window. Online member count sits under the icon.",
                30,
                function()
                    return _G.FluxCCPChatGuildButton ~= nil
                end
            ),
            chat_btn_durability = ButtonToggle(
                "chat_btn_durability",
                "Character Info",
                "Full-size Character micro button. Durability percent sits under it.",
                40,
                function()
                    return _G.FluxCCPChatDurabilityButton ~= nil
                end
            ),
            chat_btn_bags = ButtonToggle(
                "chat_btn_bags",
                "Bags",
                "Full-size Bags micro button. Same tooltip and clicks as the micromenu bags button.",
                45,
                function()
                    return _G.FluxCCPChatBagButton ~= nil
                end
            ),
            chat_copy = ButtonToggle(
                "chat_copy",
                "Copy Chat",
                "Copy the selected chat window.",
                50,
                function()
                    return _G.FluxCCPChatCopyButton ~= nil
                end
            ),
            chat_btn_options = ButtonToggle(
                "chat_btn_options",
                "FluxUI Options",
                "Gear on the chat column. Left-click opens FluxUI options. Right-click opens Blizzard settings.",
                60,
                function()
                    return _G.FluxCCPChatSettingsButton ~= nil
                end
            ),
            chat_btn_menu = ButtonToggle(
                "chat_btn_menu",
                "Chat Menu",
                "Blizzard chat menu button.",
                70,
                function()
                    return _G.ChatFrameMenuButton ~= nil
                end
            ),
        },
    }
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, _, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    if FluxOptions and FluxOptions.RegisterModuleOptions then
        FluxOptions:RegisterModuleOptions("chat", BuildChatOptions)
    end
end)

