ITTsDonationBot = ZO_CallbackObject:New()
ITTsDonationBot.name = "ITTsDonationBot"

local db = {}
local LAM2 = LibAddonMenu2
--[[ local logger = LibDebugLogger(ITTsDonationBot.name)
logger:SetEnabled(false) ]]
local chat = LibChatMessage("ITTsDonationBot", "ITTs-DB")

local SECONDS_IN_HOUR = 60 * 60
local SECONDS_IN_DAY = SECONDS_IN_HOUR * 24
local SECONDS_IN_WEEK = SECONDS_IN_DAY * 7

local worldName = GetWorldName()

local defaults = {
  settings = {
    [worldName] = {
      guilds = {
        {name = "Guild Slot #1", id = 0, disabled = true, selected = false},
        {name = "Guild Slot #2", id = 0, disabled = true, selected = false},
        {name = "Guild Slot #3", id = 0, disabled = true, selected = false},
        {name = "Guild Slot #4", id = 0, disabled = true, selected = false},
        {name = "Guild Slot #5", id = 0, disabled = true, selected = false}
      },
      guildsCache = {
        {name = "Guild Slot #1", id = 0, disabled = true, selected = false},
        {name = "Guild Slot #2", id = 0, disabled = true, selected = false},
        {name = "Guild Slot #3", id = 0, disabled = true, selected = false},
        {name = "Guild Slot #4", id = 0, disabled = true, selected = false},
        {name = "Guild Slot #5", id = 0, disabled = true, selected = false}
      },
      notifications = {
        chat = true,
        screen = true
      },
      querySelection = 1,
      queryTimeframe = "Last Week"
    }
  },
  records = {},
  tooltip = {}
}

local function inter(s, tab)
  return (s:gsub(
    "($%b{})",
    function(w)
      return tab[w:sub(3, -2)] or w
    end
  ))
end

function ITTsDonationBot:parse(str, args)
  local phrase = ""
  local template = ITTsDonationBot.i18n["ITTDB_" .. str]

  if template ~= nil then
    phrase = inter(template, args)
  end

  return phrase
end

-- --------------------
-- Commands
-- --------------------
local function CMD_CacheTooltips(guildIndex)
  if guildIndex then
    guildIndex = tonumber(guildIndex)

    if guildIndex == nil then
      guildIndex = 0
    end

    if guildIndex < 1 or guildIndex > 5 then
      chat:Print(ITTsDonationBot:parse("CMD_NO_GUILDS"))
    else
      local guildId = GetGuildId(guildIndex)

      if ITTsDonationBot:IsGuildEnabled(guildId) then
        ITTsDonationBot:ReCacheTooltips(guildId)
        chat:Print(ITTsDonationBot:parse("CMD_GENERATED"))
      else
        chat:Print(ITTsDonationBot:parse("CMD_NO_GUILDS"))
      end
    end
  else
    chat:Print(ITTsDonationBot:parse("CMD_NO_GUILDS"))
  end
end

-- --------------------
-- Create Settings
-- --------------------
local function makeSettings()
  local optionsData = {}
  local guildLotto = 1
  local lottotTicketValue = 1000
  local panelData = {
    type = "panel",
    name = ITTsDonationBot:parse("NAME"),
    author = "ghostbane"
  }

  optionsData[#optionsData + 1] = {
    type = "header",
    name = ITTsDonationBot:parse("HEADER_GUILDS")
  }

  optionsData[#optionsData + 1] = {
    type = "description",
    title = "",
    text = ITTsDonationBot:parse("SETTINGS_DESC")
  }

  for i = 1, 5 do
    optionsData[#optionsData + 1] = {
      type = "checkbox",
      name = function()
        return db.settings[worldName].guilds[i].name
      end,
      tooltip = function()
        if db.settings[worldName].guilds[i].disabled then
          return ITTsDonationBot:parse("SETTINGS_SCAN_ERROR")
        else
          return ITTsDonationBot:parse("SETTINGS_SCAN_PROMPT", {guild = db.settings[worldName].guilds[i].name})
        end
      end,
      disabled = function()
        return db.settings[worldName].guilds[i].disabled
      end,
      getFunc = function()
        return db.settings[worldName].guilds[i].selected
      end,
      setFunc = function(value)
        db.settings[worldName].guilds[i].selected = value
      end,
      default = defaults.settings[worldName].guilds[i].selected,
      reference = "ITTsDonationBotSettingsGuild" .. tostring(i)
    }
  end

  optionsData[#optionsData + 1] = {
    type = "description",
    title = "",
    text = ITTsDonationBot:parse("SETTINGS_SCAN_INFO")
  }

  optionsData[#optionsData + 1] = {
    type = "header",
    name = ITTsDonationBot:parse("HEADER_NOTIFY")
  }

  optionsData[#optionsData + 1] = {
    type = "description",
    title = "",
    text = ITTsDonationBot:parse("SETTINGS_NOTIFY")
  }

  optionsData[#optionsData + 1] = {
    type = "checkbox",
    name = ITTsDonationBot:parse("SETTINGS_CHAT"),
    getFunc = function()
      return db.settings[worldName].notifications.chat
    end,
    setFunc = function(value)
      db.settings[worldName].notifications.chat = value
    end,
    default = defaults.settings[worldName].notifications.chat
  }

  optionsData[#optionsData + 1] = {
    type = "checkbox",
    name = ITTsDonationBot:parse("SETTINGS_SCREEN"),
    getFunc = function()
      if ITT_DonationBotSettingsLogo and _desc then
        makeITTDescription()
        _desc = true
      end

      return db.settings[worldName].notifications.screen
    end,
    setFunc = function(value)
      db.settings[worldName].notifications.screen = value
    end,
    default = defaults.settings[worldName].notifications.screen
  }

  local function ITT_LottoGenerate()
    local guildId = GetGuildId(guildLotto)
    local nameList = ""
    local amountList = ""
    local nameList2 = ""
    local amountList2 = ""
    local rowCount = 0

    if not ITTsDonationBot:IsGuildEnabled(guildId) then
      return false
    end

    for i = 1, GetNumGuildMembers(guildId) do
      local displayName = GetGuildMemberInfo(guildId, i)
      local startTime = 0
      local endTime = 0

      for reportIndex = 1, #ITTsDonationBot.reportQueries do
        if ITTsDonationBot.reportQueries[reportIndex].name == db.settings[worldName].queryTimeframe then
          startTime, endTime = ITTsDonationBot.reportQueries[reportIndex].range()
        end
      end

      local amount = ITTsDonationBot:QueryValues(guildId, displayName, startTime, endTime)

      amount = math.floor(amount / lottotTicketValue)

      if amount > 0 then
        rowCount = rowCount + 1

        if rowCount <= 250 then
          nameList = nameList .. string.gsub(displayName, "@", "") .. "\n"
          amountList = amountList .. tostring(amount) .. "\n"
        else
          nameList2 = nameList2 .. string.gsub(displayName, "@", "") .. "\n"
          amountList2 = amountList2 .. tostring(amount) .. "\n"
        end
      end
    end

    ITT_LottoNameList.editbox:SetText(nameList)
    ITT_LottoAmountList.editbox:SetText(amountList)

    if rowCount > 250 then
      ITT_LottoNameList2.editbox:SetText(nameList2)
      ITT_LottoAmountList2.editbox:SetText(amountList2)
    end
  end

  local lottoOptions = {}

  lottoOptions[#lottoOptions + 1] = {
    type = "description",
    title = "",
    text = ITTsDonationBot:parse("SETTINGS_LOTTO_DESC")
  }

  lottoOptions[#lottoOptions + 1] = {
    type = "dropdown",
    name = ITTsDonationBot:parse("SETTINGS_LOTTO_SELECT"),
    tooltip = ITTsDonationBot:parse("SETTINGS_LOTTO_GUILD"),
    choices = {"Guild #1", "Guild #2", "Guild #3", "Guild #4", "Guild #5"},
    getFunc = function()
      return "Guild #1"
    end,
    setFunc = function(var)
      guildLotto = string.gsub(tostring(var), "Guild #", "")
    end,
    width = "half",
    isExtraWide = true
  }

  lottoOptions[#lottoOptions + 1] = {
    type = "editbox",
    name = ITTsDonationBot:parse("SETTINGS_LOTTO_VALUE"),
    tooltip = ITTsDonationBot:parse("SETTINGS_LOTTO_EXAMPLE"),
    getFunc = function()
      return lottotTicketValue
    end,
    setFunc = function(text)
      lottotTicketValue = text
    end,
    width = "half", --or "half" (optional)
    isExtraWide = true
  }

  ITTsDonationBot.reportQueries = {
    {
      name = ITTsDonationBot:parse("TIME_TODAY"),
      range = function()
        return ITTsDonationBot:GetTimestampOfDayStart(0), GetTimeStamp()
      end
    },
    {
      name = ITTsDonationBot:parse("TIME_YESTERDAY"),
      range = function()
        return ITTsDonationBot:GetTimestampOfDayStart(1), ITTsDonationBot:GetTimestampOfDayStart(0)
      end
    },
    {
      name = ITTsDonationBot:parse("TIME_2_DAYS"),
      range = function()
        return ITTsDonationBot:GetTimestampOfDayStart(2), ITTsDonationBot:GetTimestampOfDayStart(1)
      end
    },
    {
      name = ITTsDonationBot:parse("TIME_THIS_WEEK"),
      range = function()
        return ITTsDonationBot:GetTraderWeekStart(), ITTsDonationBot:GetTraderWeekEnd()
      end
    },
    {
      name = ITTsDonationBot:parse("TIME_LAST_WEEK"),
      range = function()
        return ITTsDonationBot:GetTraderWeekStart() - SECONDS_IN_WEEK, ITTsDonationBot:GetTraderWeekStart()
      end
    },
    {
      name = ITTsDonationBot:parse("TIME_PRIOR_WEEK"),
      range = function()
        return ITTsDonationBot:GetTraderWeekStart() - (SECONDS_IN_WEEK * 2), ITTsDonationBot:GetTraderWeekStart() - SECONDS_IN_WEEK
      end
    },
    {
      name = ITTsDonationBot:parse("TIME_7_DAYS"),
      range = function()
        return ITTsDonationBot:GetTimestampOfDayStart(7), GetTimeStamp()
      end
    },
    {
      name = ITTsDonationBot:parse("TIME_10_DAYS"),
      range = function()
        return ITTsDonationBot:GetTimestampOfDayStart(10), GetTimeStamp()
      end
    },
    {
      name = ITTsDonationBot:parse("TIME_14_DAYS"),
      range = function()
        return ITTsDonationBot:GetTimestampOfDayStart(14), GetTimeStamp()
      end
    },
    {
      name = ITTsDonationBot:parse("TIME_30_DAYS"),
      range = function()
        return ITTsDonationBot:GetTimestampOfDayStart(30), GetTimeStamp()
      end
    },
    {
      name = ITTsDonationBot:parse("TIME_TOTAL"),
      range = function()
        return 0, GetTimeStamp()
      end
    }
  }

  local function getReportNames()
    local values = {}

    for i = 1, #ITTsDonationBot.reportQueries do
      values[#values + 1] = ITTsDonationBot.reportQueries[i]["name"]
    end

    return values
  end

  local _reportNames = getReportNames()

  ITTsDonationBot._test = _reportNames

  lottoOptions[#lottoOptions + 1] = {
    type = "dropdown",
    name = ITTsDonationBot:parse("SETTINGS_LOTTO_TIMEFRAME"),
    tooltip = ITTsDonationBot:parse("SETTINGS_LOTTO_TIMEFRAME_2"),
    choices = _reportNames,
    getFunc = function()
      return db.settings[worldName].queryTimeframe
    end,
    setFunc = function(value)
      db.settings[worldName].queryTimeframe = value
    end,
    width = "half",
    isExtraWide = false
  }

  lottoOptions[#lottoOptions + 1] = {
    type = "button",
    name = ITTsDonationBot:parse("SETTINGS_LOTTO_GENERATE"),
    tooltip = ITTsDonationBot:parse("SETTINGS_LOTTO_GENERATE_COL"),
    func = ITT_LottoGenerate,
    width = "full"
  }

  lottoOptions[#lottoOptions + 1] = {
    type = "description",
    title = "",
    text = [[ ]]
  }

  lottoOptions[#lottoOptions + 1] = {
    type = "editbox",
    name = ITTsDonationBot:parse("SETTINGS_LOTTO_NAMES"),
    tooltip = ITTsDonationBot:parse("SETTINGS_LOTTO_INFO_1"),
    getFunc = function()
      return ITTsDonationBot:parse("SETTINGS_LOTTO_INFO_5")
    end,
    setFunc = function(text)
      print(text)
    end,
    isMultiline = true,
    width = "half",
    isExtraWide = true,
    reference = "ITT_LottoNameList"
  }

  lottoOptions[#lottoOptions + 1] = {
    type = "editbox",
    name = ITTsDonationBot:parse("SETTINGS_LOTTO_TICKETS"),
    tooltip = ITTsDonationBot:parse("SETTINGS_LOTTO_INFO_2"),
    getFunc = function()
      return ITTsDonationBot:parse("SETTINGS_LOTTO_INFO_6")
    end,
    setFunc = function(text)
      print(text)
    end,
    isMultiline = true,
    width = "half",
    isExtraWide = true,
    reference = "ITT_LottoAmountList"
  }

  lottoOptions[#lottoOptions + 1] = {
    type = "editbox",
    name = "",
    tooltip = ITTsDonationBot:parse("SETTINGS_LOTTO_INFO_3"),
    getFunc = function()
      return ITTsDonationBot:parse("SETTINGS_LOTTO_INFO_5")
    end,
    setFunc = function(text)
      print(text)
    end,
    isMultiline = true,
    width = "half",
    isExtraWide = true,
    reference = "ITT_LottoNameList2"
  }

  lottoOptions[#lottoOptions + 1] = {
    type = "editbox",
    name = "",
    tooltip = ITTsDonationBot:parse("SETTINGS_LOTTO_INFO_4"),
    getFunc = function()
      return ITTsDonationBot:parse("SETTINGS_LOTTO_INFO_6")
    end,
    setFunc = function(text)
      print(text)
    end,
    isMultiline = true,
    width = "half",
    isExtraWide = true,
    reference = "ITT_LottoAmountList2"
  }

  optionsData[#optionsData + 1] = {
    type = "submenu",
    name = ITTsDonationBot:parse("SETTINGS_LOTTO_NAME"),
    tooltip = "$$$", --(optional)
    controls = lottoOptions
  }

  optionsData[#optionsData + 1] = {
    type = "description",
    title = "",
    text = [[ ]]
  }

  optionsData[#optionsData + 1] = {
    type = "description",
    title = "",
    text = [[ ]]
  }

  optionsData[#optionsData + 1] = {
    type = "texture",
    image = "ITTsDonationBot/itt-logo.dds",
    imageWidth = "192",
    imageHeight = "192",
    reference = "ITT_DonationBotSettingsLogo"
  }

  local _desc = true

  local function makeITTDescription()
    local ITTDTitle = WINDOW_MANAGER:CreateControl("ITTsDonationBotSettingsLogoTitle", ITT_DonationBotSettingsLogo, CT_LABEL)
    ITTDTitle:SetFont("$(BOLD_FONT)|$(KB_18)|soft-shadow-thin")
    ITTDTitle:SetText("|Cfcba03INDEPENDENT TRADING TEAM")
    ITTDTitle:SetDimensions(240, 31)
    ITTDTitle:SetHorizontalAlignment(1)
    ITTDTitle:SetAnchor(TOP, ITT_DonationBotSettingsLogo, BOTTOM, 0, 40)

    local ITTDLabel = WINDOW_MANAGER:CreateControl("ITTsDonationBotSettingsLogoTitleServer", ITTsDonationBotSettingsLogoTitle, CT_LABEL)
    ITTDLabel:SetFont("$(MEDIUM_FONT)|$(KB_16)|soft-shadow-thick")
    ITTDLabel:SetText("|C646464PC EU")
    ITTDLabel:SetDimensions(240, 21)
    ITTDLabel:SetHorizontalAlignment(1)
    ITTDLabel:SetAnchor(TOP, ITTsDonationBotSettingsLogoTitle, BOTTOM, 0, -5)

    ITT_HideMePls:SetHidden(true)
  end

  optionsData[#optionsData + 1] = {
    type = "checkbox",
    name = "HideMePls",
    getFunc = function()
      if ITT_DonationBotSettingsLogo ~= nil and _desc then
        makeITTDescription()
        _desc = false
      end

      return false
    end,
    setFunc = function(value)
      return false
    end,
    default = false,
    disabled = true,
    reference = "ITT_HideMePls"
  }

  return panelData, optionsData
end

-- --------------------
-- Event Callbacks
-- --------------------
local function OnPlayerActivated(eventCode)
  EVENT_MANAGER:UnregisterForEvent(ITTsDonationBot.name, eventCode)

  ITTsDonationBot:Initialize()
end

local function OnHistoryResponseReceived(ev, guildId, category)
  if category == GUILD_HISTORY_BANK and ITTsDonationBot:IsGuildEnabled(guildId) then
    ITTsDonationBot:RunScanCycle(guildId)
  end
end

local function ITTsDonationBot_OnAddOnLoaded(eventCode, addOnName)
  if addOnName == ITTsDonationBot.name then
    db = ZO_SavedVars:NewAccountWide("ITTsDonationBotSettings", 1, nil, defaults)

    local panelData, optionsData = makeSettings()

    LAM2:RegisterAddonPanel("ITTsDonationBotOptions", panelData)
    LAM2:RegisterOptionControls("ITTsDonationBotOptions", optionsData)

    ITTsDonationBot.db = db

    EVENT_MANAGER:RegisterForEvent(ITTsDonationBot.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    EVENT_MANAGER:UnregisterForEvent(ITTsDonationBot.name, eventCode)

    SLASH_COMMANDS["/itt-donation-cache"] = CMD_CacheTooltips
  end
end
-- --------------------
-- Methods
-- --------------------
function ITTsDonationBot:Initialize()
  EVENT_MANAGER:RegisterForEvent(ITTsDonationBot.name, EVENT_GUILD_HISTORY_RESPONSE_RECEIVED, OnHistoryResponseReceived)
  EVENT_MANAGER:RegisterForEvent(
    ITTsDonationBot.name,
    EVENT_GUILD_SELF_JOINED_GUILD,
    function(_, _, newGuildId)
      ITTsDonationBot:CheckGuildPermissions(newGuildId)
    end
  )
  EVENT_MANAGER:RegisterForEvent(
    ITTsDonationBot.name,
    EVENT_GUILD_SELF_LEFT_GUILD,
    function()
      ITTsDonationBot:CheckGuildPermissions()
    end
  )

  if not db.records[worldName] then
    db.records[worldName] = {}
  end
  if not db.tooltip[worldName] then
    db.tooltip[worldName] = {}
  end

  self:CheckGuildPermissions()
  self:RequestAllHistory()

  ITTsDonationBot.Roster:Enable()
end

function ITTsDonationBot:CheckGuildPermissions(newGuildId)
  for i = 1, 5 do
    local guildId = GetGuildId(i)
    local control = _G["ITTsDonationBotSettingsGuild" .. tostring(i)]

    if guildId > 0 then
      local guildName = GetGuildName(guildId)
      local cachedSetting = db.settings[worldName].guilds[i].selected

      if guildId ~= db.settings[worldName].guildsCache[i].id then
        for inc = 1, 5 do
          if db.settings[worldName].guildsCache[inc].id == guildId then
            cachedSetting = db.settings[worldName].guildsCache[inc].selected
          end
        end
      end

      db.settings[worldName].guilds[i].name = guildName
      db.settings[worldName].guilds[i].id = guildId
      db.settings[worldName].guilds[i].disabled = not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_VIEW_GOLD)

      if DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_VIEW_GOLD) then
        if newGuildId and db.settings[worldName].guilds[i].id == newGuildId then
          db.settings[worldName].guilds[i].selected = true
          db.settings[worldName].guilds[i].disabled = false
        elseif "Guild Slot #" .. tostring(i) == db.settings[worldName].guildsCache[i].name then
          db.settings[worldName].guilds[i].selected = true
          db.settings[worldName].guilds[i].disabled = false
        end
      else
        db.settings[worldName].guilds[i].selected = false
        db.settings[worldName].guilds[i].disabled = true
      end
    else
      db.settings[worldName].guilds[i].name = "Guild Slot #" .. tostring(i)
      db.settings[worldName].guilds[i].id = 0
      db.settings[worldName].guilds[i].disabled = true
      db.settings[worldName].guilds[i].selected = false
    end

    if control then
      control.label:SetText(db.settings[worldName].guilds[i].name)
      control:UpdateValue()
      control:UpdateDisabled()
    end

    if db.settings[worldName].guilds[i].selected then
      if not db.records[worldName][db.settings[worldName].guilds[i].id] then
        db.records[worldName][db.settings[worldName].guilds[i].id] = {}
      end
    end
  end

  ZO_DeepTableCopy(db.settings[worldName].guilds, db.settings[worldName].guildsCache)
end

function ITTsDonationBot:HasTooltipInfo(guildId, displayName)
  local value = false

  if db.tooltip[worldName][guildId] and db.tooltip[worldName][guildId][displayName] then
    if db.tooltip[worldName][guildId][displayName].total and db.tooltip[worldName][guildId][displayName].total > 0 then
      value = true
    end
  end

  return value
end

function ITTsDonationBot:CreateTooltipInfo(guildId, displayName)
  if db.records[worldName][guildId][displayName] then
    local store = db.records[worldName][guildId][displayName]
    local latestDonations = {}
    local indexCheck = 1

    local today = self:QueryValues(guildId, displayName, self:GetTimestampOfDayStart(0), GetTimeStamp())
    local thisWeek = self:QueryValues(guildId, displayName, self:GetTraderWeekStart(), self:GetTraderWeekEnd())
    local lastWeek = self:QueryValues(guildId, displayName, self:GetTraderWeekStart() - SECONDS_IN_WEEK, self:GetTraderWeekStart())
    local priorWeek =
      self:QueryValues(guildId, displayName, ITTsDonationBot:GetTraderWeekStart() - (SECONDS_IN_WEEK * 2), ITTsDonationBot:GetTraderWeekStart() - SECONDS_IN_WEEK)

    local summary = {
      log = {},
      today = today,
      thisWeek = thisWeek,
      lastWeek = lastWeek,
      priorWeek = priorWeek,
      total = 0
    }

    local keyset = {}
    local n = 0

    for k, v in pairs(store) do
      n = n + 1
      keyset[n] = k

      if v.amount then
        summary.total = summary.total + v.amount
      end
    end

    table.sort(
      keyset,
      function(a, b)
        return a > b
      end
    )

    for i = 1, 5 do
      if keyset[i] then
        id = keyset[i]
        value = store[id]

        -- formatedTime = os.date("*t", value.timestamp)

        -- local hour = formatedTime.hour
        -- local min = formatedTime.min
        -- local day = formatedTime.day
        -- local month = formatedTime.month

        -- if hour < 10 then hour = '0'..tostring(hour) end
        -- if min < 10 then min = '0'..tostring(min) end
        -- if day < 10 then min = '0'..tostring(day) end
        -- if month < 10 then min = '0'..tostring(month) end

        -- local timeString = os.date('%x',value.timestamp)
        -- local timeString = os.date(value.timestamp,'%d'..sep..'%m'..sep..'%Y %H:%M')

        local sep = "/"

        if GetCVar("language.2") == "de" then
          sep = "."
        end

        -- timeString = day..sep..month..sep..formatedTime.year..' '..hour..':'..min
        local timeString = os.date("%d" .. sep .. "%m" .. sep .. "%Y %H:%M", value.timestamp)

        summary.log[6 - i] = {amount = value.amount, time = timeString}
      else
        summary.log[6 - i] = {none = true}
      end
    end

    if not db.tooltip[worldName][guildId] then
      db.tooltip[worldName][guildId] = {}
    end
    if not db.tooltip[worldName][guildId][displayName] then
      db.tooltip[worldName][guildId][displayName] = {}
    end

    db.tooltip[worldName][guildId][displayName] = summary
  end
end

function ITTsDonationBot:GetTooltipCache(guildId, displayName)
  local tooltipData = {}

  if db.tooltip[worldName][guildId] and db.tooltip[worldName][guildId][displayName] then
    tooltipData = db.tooltip[worldName][guildId][displayName]
  end

  return tooltipData
end

function ITTsDonationBot:SaveEvent(guildId, eventIndex)
  local timeStamp = GetTimeStamp()
  local eventType, secsSinceEvent, displayName, amount, _, _, _, _, id = GetGuildEventInfo(guildId, GUILD_HISTORY_BANK, eventIndex)

  if eventType == GUILD_EVENT_BANKGOLD_ADDED and secsSinceEvent >= 0 then
    local eventTimestamp = timeStamp - secsSinceEvent
    if eventTimestamp < 0 then
      eventTimestamp = timestamp
    end
    local eventId = GetGuildEventId(guildId, category, eventIndex)
    local eventIdNum = tonumber(Id64ToString(eventId))

    if not db.records[worldName][guildId][displayName] then
      db.records[worldName][guildId][displayName] = {}
    end

    if secsSinceEvent < SECONDS_IN_DAY then
      if not db.records[worldName][guildId][displayName][id] then
        self:DisplayNotifications(guildId, displayName, amount, secsSinceEvent)
      end
    end

    if not db.records[worldName][guildId][displayName][id] then
      db.records[worldName][guildId][displayName][id] = {amount = amount, timestamp = eventTimestamp}
    elseif db.records[worldName][guildId][displayName][id] and not db.records[worldName][guildId][displayName][id].eventTimestamp then
      db.records[worldName][guildId][displayName][id] = {amount = amount, timestamp = eventTimestamp}
    end
  end
end

function ITTsDonationBot:DisplayNotifications(guildId, displayName, amount, seconds)
  local shoutMsg =
    ITTsDonationBot:parse(
    "NOTIFICATION",
    {
      user = "|Caaff00" .. displayName .. "|CFFFFFF",
      amount = "|Cfce803" .. ZO_LocalizeDecimalNumber(amount) .. " |t14:14:EsoUI/Art/currency/currency_gold.dds|t|CFFFFFF",
      guild = "|cffa600" .. GetGuildName(guildId) .. "|CFFFFFF",
      time = "|cFFFFFF" .. ZO_FormatDurationAgo(seconds)
    }
  )

  displayName = ZO_LinkHandler_CreatePlayerLink(displayName)

  local msg =
    ITTsDonationBot:parse(
    "NOTIFICATION",
    {
      user = "|Caaff00" .. displayName .. "|CFFFFFF",
      amount = "|Cfce803" .. ZO_LocalizeDecimalNumber(amount) .. " |t14:14:EsoUI/Art/currency/currency_gold.dds|t|CFFFFFF",
      guild = "|cffa600" .. GetGuildName(guildId) .. "|CFFFFFF",
      time = "|cFFFFFF" .. ZO_FormatDurationAgo(seconds)
    }
  )

  if db.settings[worldName].notifications.chat then
    chat:Print(msg)
  end

  if db.settings[worldName].notifications.screen then
    local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.TELVAR_TRANSACT)
    params:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_POI_DISCOVERED)
    params:SetText(shoutMsg)
    CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
  end

  zo_callLater(
    function()
      LibGuildRoster:Refresh()
    end,
    2000
  )
end

function ITTsDonationBot:RunScanCycle(guildId, forceIndex)
  self.scanHistory = self.scanHistory or {}
  local start = self.scanHistory[guildId] or 1
  local numGuildEvents = GetNumGuildEvents(guildId, GUILD_HISTORY_BANK)

  if forceIndex then
    start = 1
  end

  for index = start, numGuildEvents do
    self:SaveEvent(guildId, index)
  end

  self.scanHistory[guildId] = numGuildEvents + 1

  self:ReCacheTooltips(guildId)
end

function ITTsDonationBot:ReCacheTooltips(guildId)
  if db.records[worldName][guildId] then
    for k, v in pairs(db.records[worldName][guildId]) do
      self:CreateTooltipInfo(guildId, k)
    end
  end
end

function ITTsDonationBot:GetGuildMap()
  local guilds = {}

  for i = 1, 5 do
    if db.settings[worldName].guilds[i].selected and not db.settings[worldName].guilds[i].disabled then
      guilds[#guilds + 1] = db.settings[worldName].guilds[i].id
    end
  end

  return guilds
end

function ITTsDonationBot:IsGuildEnabled(guildId)
  local list = self:GetGuildMap()
  local condition = false

  for i = 1, #list do
    if guildId == list[i] then
      condition = true
      break
    end
  end

  return condition
end

function ITTsDonationBot:QueryValues(guildId, displayName, startTime, endTime)
  local value = 0

  if db.records[worldName][guildId] and db.records[worldName][guildId][displayName] then
    for key, record in pairs(db.records[worldName][guildId][displayName]) do
      if record.timestamp and record.timestamp > startTime and record.timestamp < endTime then
        value = record.amount + value
      end
    end
  end

  return value
end

function ITTsDonationBot:RequestAllHistory()
  for _, guildId in pairs(self:GetGuildMap()) do
    self:RequestHistory(guildId, GUILD_HISTORY_BANK)
  end
end

function ITTsDonationBot:RequestHistory(gID, guildHistoryCategory)
  local cooldown = 1000 * 60

  -- logger:Info('ITTsDonationBot:RequestHistory() running -', GetGuildName(gID)..'-'..guildHistoryCategory)

  if DoesGuildHistoryCategoryHaveOutstandingRequest(gID, guildHistoryCategory) == false and IsGuildHistoryCategoryRequestQueued(gID, guildHistoryCategory) == false then
    if DoesGuildHistoryCategoryHaveMoreEvents(gID, guildHistoryCategory) then
      -- logger:Info('More history exists for ',GetGuildName(gID)..'-'..guildHistoryCategory)

      if RequestMoreGuildHistoryCategoryEvents(gID, guildHistoryCategory) then
        -- logger:Info('Requesting Guild History:',GetGuildName(gID)..'-'..guildHistoryCategory)
        zo_callLater(
          function()
            ITTsDonationBot:RequestHistory(gID, guildHistoryCategory)
          end,
          cooldown
        )
      else
        -- logger:Info('Request cooldown for ',GetGuildName(gID)..'-'..guildHistoryCategory,' has not expired yet, re-calling in a few minutes')
        zo_callLater(
          function()
            ITTsDonationBot:RequestHistory(gID, guildHistoryCategory)
          end,
          cooldown
        )
      end
    else
      -- logger:Info('No more history exists for ',GetGuildName(gID)..'-'..guildHistoryCategory)
      -- logger:Info('Total:',GetNumGuildEvents(gID, guildHistoryCategory))

      if GetNumGuildEvents(gID, guildHistoryCategory) > 0 and db.records[worldName][gId] == nil then
        self:RunScanCycle(gID, 1)
      end
    end
  else
    -- logger:Info('Scan requirements not met: Trying again in 1m')
    zo_callLater(
      function()
        ITTsDonationBot:RequestHistory(gID, guildHistoryCategory)
      end,
      cooldown
    )
  end
end

function ITTsDonationBot:GetTimestampOfDayStart(offset)
  local timeObject = os.date("*t", os.time() - (24 * offset) * 60 * 60)
  local hours = timeObject.hour
  local mins = timeObject.min
  local secs = timeObject.sec
  local UTCMidnightOffset = (hours * SECONDS_IN_HOUR) + (mins * 60) + secs
  local recordTimestamp = os.time(timeObject)

  return recordTimestamp - UTCMidnightOffset
end

function ITTsDonationBot:GetTraderWeekEnd()
  local _, time, _ = GetGuildKioskCycleTimes()

  return time
end

function ITTsDonationBot:GetTraderWeekStart()
  local time = self:GetTraderWeekEnd()

  return time - SECONDS_IN_WEEK
end

-- --------------------
-- Attach Listeners
-- --------------------
EVENT_MANAGER:RegisterForEvent(ITTsDonationBot.name, EVENT_ADD_ON_LOADED, ITTsDonationBot_OnAddOnLoaded)
