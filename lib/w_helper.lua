------------------------------------------------------------------------------------------------------------------------
---  Widget Helper Functions
------------------------------------------------------------------------------------------------------------------------
---
---  wHelper library with classes and functions for widget support:
---
---    Debug class for debug messages with context (widget key, widget number and function name):
---      Debug:new(widgetNo, widgetFunction)
---      Debug:info(debugText)
---      Debug:warning(debugText)
---      Debug:error(debugText)
---
---    Functions:
---      versionStringToNumber(versionString)
---      versionNumberToString(versionNumber)
---      isValidVersion(versionNumber)
---      existText(text)
---      existSource(source)
---      getSourceName(source)
---      splitLines(text, separator)
---      addLine(baseText, addText, separator)
---      capitalizeFirstLetter(str)
---      return function(parameters)
---
---  Version:                 1.1.0
---  Development Environment: Ethos X20S Simulator Version 1.6.3
---  Test Environment:        FrSky Tandem X20 | Ethos 1.6.3 EU
---
---  Author: Andreas Kuhl (https://github.com/andreaskuhl)
---  License: GPL 3.0
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--- Modul locals (constants, variables, ...)
------------------------------------------------------------------------------------------------------------------------

-- library constants
local ANSI      = {
    -- Standard Colors
    BLACK          = "\27[30m",
    RED            = "\27[31m",
    GREEN          = "\27[32m",
    YELLOW         = "\27[33m",
    BLUE           = "\27[34m",
    MAGENTA        = "\27[35m",
    CYAN           = "\27[36m",
    WHITE          = "\27[37m",
    -- Bright Colors
    BRIGHT_BLACK   = "\27[90m",
    BRIGHT_RED     = "\27[91m",
    BRIGHT_GREEN   = "\27[92m",
    BRIGHT_YELLOW  = "\27[93m",
    BRIGHT_BLUE    = "\27[94m",
    BRIGHT_MAGENTA = "\27[95m",
    BRIGHT_CYAN    = "\27[96m",
    BRIGHT_WHITE   = "\27[97m",
    -- Reset
    RESET          = "\27[0m"
}

-- ANSI codes for debug output
local INFO_TYPE = { INFO = ANSI.GREEN, WARNING = ANSI.YELLOW, ERROR = ANSI.RED }

-- library structure
local wHelper   = {
    -- configuration parameters
    widgetKey     = "",    -- widget key
    widgetVersion = "",    -- widget version
    debugMode     = false, -- debug mode
}


------------------------------------------------------------------------------------------------------------------------
--- Debug class for widget debug messages
------------------------------------------------------------------------------------------------------------------------
wHelper.Debug         = {}
wHelper.Debug.__index = wHelper.Debug

------------------------------------------------------------------------------------------------------------------------
---  Debug output, if DEBUG_MODE is true. Example: "0123456 Widget WDGTMPL - paint(): Paint widget status."
local function debugMessage(widgetNo, widgetFunction, debugText, debugType)
    if not wHelper.debugMode then return end
    if not debugText then debugText = "" end
    if not debugType then debugType = INFO_TYPE.INFO end

    local debugTick = string.format("%06d ", math.floor(os.clock() * 1000))
    local debugPrefix = debugType .. debugTick .. "Widget " .. wHelper.widgetKey
    if widgetNo > 0 then
        debugPrefix = string.format("%s#%02d", debugPrefix, widgetNo)
    else
        debugPrefix = debugPrefix .. "   "
    end
    if wHelper.existText(widgetFunction) then
        debugPrefix = debugPrefix .. " - " .. widgetFunction .. "()"
    end
    if wHelper.existText(debugText) then
        debugText = ": " .. debugText
    end

    print(debugPrefix .. debugText .. ANSI.RESET)
end

------------------------------------------------------------------------------------------------------------------------
--- Initialize debug for widget debugInfo
function wHelper.Debug:new(widgetNo, widgetFunction)
    local self = setmetatable({}, wHelper.Debug)
    self.widgetNo = widgetNo or 0
    self.widgetFunction = widgetFunction or ""
    return self
end

------------------------------------------------------------------------------------------------------------------------
---  Info
function wHelper.Debug:info(debugText)
    debugMessage(self.widgetNo, self.widgetFunction, debugText, INFO_TYPE.INFO)
    return self
end

------------------------------------------------------------------------------------------------------------------------
---  Shortcuts for warning
function wHelper.Debug:warning(debugText)
    debugMessage(self.widgetNo, self.widgetFunction, debugText, INFO_TYPE.WARNING)
    return self
end

------------------------------------------------------------------------------------------------------------------------
---  Shortcuts for error
function wHelper.Debug:error(debugText)
    debugMessage(self.widgetNo, self.widgetFunction, debugText, INFO_TYPE.ERROR)
    return self
end

------------------------------------------------------------------------------------------------------------------------
--- Convert version string "x.y.z" to a number xyz (e.g., "1.2.3" -> 10203).
function wHelper.versionStringToNumber(versionString)
    local major, minor, patch = versionString:match("(%d+)%.(%d+)%.(%d+)")
    if major and minor and patch then
        return tonumber(major) * 10000 + tonumber(minor) * 100 + tonumber(patch)
    else
        wHelper.Debug:new(0, "wHelper.versionStringToNumber")
            :error("Invalid version format. Expected x.y.z " .. versionString)
        return 0
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Convert version number xyz to a string "x.y.z" (e.g., 10203 -> "1.2.3").
function wHelper.versionNumberToString(versionNumber)
    local s = string.format("%06d", versionNumber)
    return string.format("%d.%d.%d", tonumber(s:sub(1, 2)), tonumber(s:sub(3, 4)), tonumber(s:sub(5, 6)))
end

------------------------------------------------------------------------------------------------------------------------
--- Check if the version number is valid and compare it with the WIDGET_VERSION.
function wHelper.isValidVersion(versionNumber)
    local debug             = wHelper.Debug:new(0, "wHelper.isValidVersion")
    local widgetVersionNumber = wHelper.versionStringToNumber(wHelper.widgetVersion)

    if not versionNumber or (type(versionNumber) ~= "number") or (versionNumber == 0) then
        debug:error("no version found or not valid -> abort read")
        return false
    end

    debug:info(
        string.format("data version %s (%d), widget version is %s (%d)", wHelper.versionNumberToString(versionNumber),
            versionNumber,
            wHelper.widgetVersion, widgetVersionNumber))

    if versionNumber > widgetVersionNumber then
        debug:error("stored data is newer than widget version -> abort read and use defaults")
        return false
    elseif versionNumber < widgetVersionNumber then
        debug:warning(
            "stored data is older than widget version - > read stored data and use defaults for new parameters")
    else
        debug:info("version fit to widget version -> read stored data")
    end

    return true
end

------------------------------------------------------------------------------------------------------------------------
--- Check if the text exists and is not empty.
function wHelper.existText(text)
    return (text ~= nil) and (text ~= "")
end

------------------------------------------------------------------------------------------------------------------------
--- Check if the source exists and is valid.
function wHelper.existSource(source)
    return (source ~= nil) and (source:name() ~= "") and (source:name() ~= "---")
end

------------------------------------------------------------------------------------------------------------------------
--- Check if the source exists and is valid.
function wHelper.getSourceName(source)
    if wHelper.existSource(source) then
        return source:name()
    else
        return "---"
    end
end

------------------------------------------------------------------------------------------------------------------------
---  Split text into lines based on a specified separator. Default separator is "_n_".
function wHelper.splitLines(text, separator)
    local lines = {}
    if not wHelper.existText(text) then return lines end
    if ((separator == nil) or separator == "") then separator = "_n_" end -- set default
    text = text ..
        separator                                                         -- Add separator at the end to capture the last line
    for line in string.gmatch(text, "(.-)" .. separator) do               -- Split text into lines
        table.insert(lines, line)
    end
    return lines
end

------------------------------------------------------------------------------------------------------------------------
---  Add text to baseText with a separator if baseText already contains text. Default separator is "_n_".
function wHelper.addLine(baseText, addText, separator)
    if ((separator == nil) or separator == "") then separator = "_n_" end -- set default
    if addText == nil then return baseText end
    if wHelper.existText(baseText) then
        baseText = baseText .. separator .. addText
    else
        baseText = addText
    end
    return baseText
end

------------------------------------------------------------------------------------------------------------------------
--- Capitalize first letter of a strings
function wHelper.capitalizeFirstLetter(str)
    return (str:gsub("^%l", string.upper))
end

-----------------------------------------------------------------------------------------------------------------------
--- Library settings and export
return function(parameters)
    wHelper.widgetVersion = parameters.widgetVersion
    wHelper.widgetKey     = parameters.widgetKey
    wHelper.debugMode     = parameters.debugMode
    return wHelper
end
