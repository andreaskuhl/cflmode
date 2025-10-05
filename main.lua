------------------------------------------------------------------------------------------------------------------------
---                 CFLMODE | Colored Flight Mode - Widget für FrSky Ethos
---
---  FrSky Ethos widget for color display of the current flight mode.
---
---  Documentation: file://./readme.md
---
---  Development Environment: Ethos X20S Simulator Version 1.6.3
---  Test Environment:        FrSky Tandem X20 | Ethos 1.6.3 EU
---
---  Author: Andreas Kuhl (https://github.com/andreaskuhl)
---  License: GPL 3.0
---
---  Basic history:
---    Idea by Andreas Rieken
---    v1.0.0 Andreas Kuhl (basic development) -> Colored Flight Mode
---
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--- Modul locals (constants & variables)
------------------------------------------------------------------------------------------------------------------------

--- Application control and information
local WIDGET_VERSION          = "1.0.0"                                 -- version information
local WIDGET_KEY              = "CFLMODE"                               -- unique widget key (max. 7 characters)
local WIDGET_AUTOR            = "Andreas Kuhl (github.com/andreaskuhl)" -- author information
local DEBUG_MODE              = false                                    -- true: show debug information, false: release mode
local widgetCounter           = 0                                       -- debug: counter for widget instances (0 = no instance)
local MAX_FLIGHT_MODES        = 10                                      -- maximum number of flight modes

--- Libraries
local wHelper                 = {} -- widget helper library
local wPaint                  = {} -- widget paint library
local wConfig                 = {} -- widget config library
local wStorage                = {} -- widget storage library

--- Translation
local STR                     = assert(loadfile("i18n/i18n.lua"))().translate -- load i18n and get translate function
local WIDGET_NAME_MAP         = assert(loadfile("i18n/w_name.lua"))()         -- load widget name map
local currentLocale           = system.getLocale()                            -- current system language

--- User interface
local FONT_SIZES              = {
    FONT_XS, FONT_S, FONT_STD, FONT_L, FONT_XL, FONT_XXL }                       -- global font IDs (1-5)
local FONT_SIZE_SELECTION     = {
    { "XS", 1 }, { "S", 2 }, { "M", 3 }, { "L", 4 }, { "XL", 5 }, { "XXL", 6 } } -- list for config listbox

--- widget defaults
local FONT_SIZE_INDEX_DEFAULT = 4                   -- font size index default
local BG_COLOR_TITLE_DEFAULT  = lcd.RGB(40, 40, 40) -- title background  -> dark gray
local TX_COLOR_TITLE_DEFAULT  = COLOR_WHITE         -- title text        -> white

------------------------------------------------------------------------------------------------------------------------
--- Local Helper functions
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--- Load and init Libraries.
local function initLibraries()
    -- load libraries with dependencies
    wHelper = dofile("lib/w_helper.lua")({ widgetVersion = WIDGET_VERSION, widgetKey = WIDGET_KEY, debugMode = DEBUG_MODE })
    wPaint = dofile("lib/w_paint.lua")({ wHelper = wHelper })
    wConfig = dofile("lib/w_config.lua")({ wHelper = wHelper })
    wStorage = dofile("lib/w_storage.lua")({ wHelper = wHelper })

    wHelper.Debug:new(0, "initLibraries"):info("libraries loaded")
end

------------------------------------------------------------------------------------------------------------------------
-- Check if the system language has changed and reload i18n if necessary.
local function updateLanguage(widget)
    local localeNow = system.getLocale()
    if localeNow ~= currentLocale then -- Language has changed, reload i18n
        wHelper.Debug:new(widget.no, "updateLanguage")
            :info("Language changed from " .. currentLocale .. " to " .. localeNow)
        STR = assert(loadfile("i18n/i18n.lua"))().translate
        currentLocale = localeNow
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Widget handler
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Handler to get the widget name in the current system language.
local function name() -- Widget name (ASCII) - only for name() Handler
    wHelper.Debug:new(0, "name"):info()
    local lang = system.getLocale and system.getLocale() or "en"
    return WIDGET_NAME_MAP[lang] or WIDGET_NAME_MAP["en"]
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to create a new widget instance with default values.
local function create()
    widgetCounter = widgetCounter + 1
    local debug = wHelper.Debug:new(widgetCounter, "create"):info()

    local FLIGHT_MODE_COLORS = { -- default flight mode colors
        { bgColor = COLOR_GREEN,   txColor = COLOR_BLACK },
        { bgColor = COLOR_YELLOW,  txColor = COLOR_BLACK },
        { bgColor = COLOR_RED,     txColor = COLOR_BLACK },
        { bgColor = COLOR_BLUE,    txColor = COLOR_BLACK },
        { bgColor = COLOR_CYAN,    txColor = COLOR_BLACK },
        { bgColor = COLOR_MAGENTA, txColor = COLOR_BLACK },
        { bgColor = COLOR_ORANGE,  txColor = COLOR_BLACK },
        { bgColor = COLOR_YELLOW,  txColor = COLOR_BLACK },
        { bgColor = COLOR_WHITE,   txColor = COLOR_BLACK },
        { bgColor = COLOR_BLACK,   txColor = COLOR_WHITE },
    }

    --- Create widget data structure with default values.r
    return {
        -- widget variables
        no                   = widgetCounter,           -- widget instance number
        width                = nil,                     -- widget height
        height               = nil,                     -- widget width
        flightModeValue      = -1,                      -- flight mode number [0..31], - 1 = no flight mode
        flightModeText       = "",                      -- flight mode text

        widgetFontSizeIndex  = FONT_SIZE_INDEX_DEFAULT, -- index of font size
        flightModeNumberShow = true,                    -- flight mode number show switch
        flightModeColors     = FLIGHT_MODE_COLORS,      -- default flight mode colors

        titleShow            = true,                    -- title show switch
        titleColorUse        = true,                    -- title color switch
        titleBgColor         = BG_COLOR_TITLE_DEFAULT,  -- title background color
        titleTxColor         = TX_COLOR_TITLE_DEFAULT,  -- title text color

        isFlightModeValid    = function(self)
            return self.flightModeValue >= 0 and self.flightModeValue < MAX_FLIGHT_MODES
        end,
        getFlightModeBgColor = function(self)
            if not self:isFlightModeValid() then return BG_COLOR_TITLE_DEFAULT end
            return self.flightModeColors[self.flightModeValue + 1].bgColor
        end,
        getFlightModeTxColor = function(self)
            if not self:isFlightModeValid() then return TX_COLOR_TITLE_DEFAULT end
            return self.flightModeColors[self.flightModeValue + 1].txColor
        end,
    }
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to wake up the widget (check for source value changes and initiating redrawing if necessary).
local function wakeup(widget)
    local debug = wHelper.Debug:new(widget.no, "wakeup")
    local flightMode = system.getSource({ category = CATEGORY_FLIGHT, member = FLIGHT_CURRENT_MODE })

    if not wHelper.existSource(flightMode) then
        widget.flightModeValue = -1
        widget.flightModeText = ""
        debug:error(string.format("no flight mode "))
        return
    end

    if widget.flightModeValue ~= flightMode:value() then
        widget.flightModeValue = flightMode:value()
        widget.flightModeText = flightMode:stringValue()
        debug:info(string.format("flight mode changed to %d - '%s'", widget.flightModeValue, widget.flightModeText))
        lcd.invalidate()
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to paint (draw) the widget.
local function paint(widget)
    --------------------------------------------------------------------------------------------------------------------
    --- Paint title text.
    local function paintTitle()
        -- local debug = wHelper.Debug:new(widget.no, "paintTitle"):info()
        if widget.titleShow ~= true then return end -- title disabled
        if widget.titleColorUse then
            -- title background and title text color
            wPaint.title(STR("TitleText"), widget.titleBgColor, widget.titleTxColor)
        else
            -- use flight mode colors
            wPaint.title(STR("TitleText"), widget:getFlightModeBgColor(), widget:getFlightModeTxColor())
        end
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint background, set text color and paint state text (or debug information in debug mode).
    local function paintWidget()
        -- local debug = wHelper.Debug:new(widget.no, "paintWidget"):info()
        assert(widget:isFlightModeValid(), "flight mode value not defined")
        local text = ""

        --- paint background
        lcd.color(widget:getFlightModeBgColor())
        lcd.drawFilledRectangle(0, 0, widget.width, widget.height)

        --- paint title and footer
        paintTitle()

        ---  paint widget text
        lcd.color(widget:getFlightModeTxColor())
        if widget.flightModeNumberShow then
            text = string.format("%d-%s", widget.flightModeValue, widget.flightModeText)
        else
            text = widget.flightModeText
        end
        wPaint.widgetText(text, FONT_SIZES[widget.widgetFontSizeIndex])
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint source missed (no valid source selected) in red on black background.
    local function paintSourceMissed()
        local debug = wHelper.Debug:new(widget.no, "paintSourceMissed")
        local errorText = ""
        lcd.color(COLOR_BLACK)
        lcd.drawFilledRectangle(0, 0, widget.width, widget.height)

        --- paint title
        paintTitle()

        errorText = STR("NoSource")
        debug:warning("source flight mode not defined")

        -- paint "Source missed" text
        lcd.color(COLOR_RED)
        wPaint.widgetText(errorText, FONT_S)
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint main
    wHelper.Debug:new(widget.no, "paint"):info()

    updateLanguage(widget)
    widget.width, widget.height = lcd.getWindowSize() -- set the actual widget size (always if the layout has been changed)
    wPaint.init({ widgetHeight = widget.height, widgetWidth = widget.width })

    if widget:isFlightModeValid() then
        paintWidget()
    else
        paintSourceMissed()
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to configure the widget (show configuration form).
local function configure(widget)
    local debug = wHelper.Debug:new(widget.no, "configure"):info()
    updateLanguage(widget) -- check if system language has changed
    wConfig.init({ form = form, widget = widget, STR = STR })
    local line = {}

    -- widget
    wConfig.addChoiceField("widgetFontSizeIndex", FONT_SIZE_SELECTION)
    wConfig.addBooleanField("flightModeNumberShow")

    -- title
    wConfig.startPanel("Title")
    wConfig.addBooleanField("titleShow")
    wConfig.addBooleanField("titleColorUse")
    wConfig.addColorField("titleBgColor")
    wConfig.addColorField("titleTxColor")
    wConfig.endPanel()

    -- colors
    for i = 1, MAX_FLIGHT_MODES do
        wConfig.startPanel("FlightModeColors", i)
        line = wConfig.addLine("BgColor", i)
        form.addColorField(line, nil, function() return widget.flightModeColors[i].bgColor end,
            function(value) widget.flightModeColors[i].bgColor = value end)
        line = wConfig.addLine("TxColor", i)
        form.addColorField(line, nil, function() return widget.flightModeColors[i].txColor end,
            function(value) widget.flightModeColors[i].txColor = value end)
        wConfig.endPanel()
    end

    -- widget Info
    wConfig.startPanel("Info")
    wConfig.addStaticText("Widget", STR("WidgetName"))
    wConfig.addStaticText("Version", WIDGET_VERSION)
    wConfig.addStaticText("Author", WIDGET_AUTOR)
    wConfig.endPanel()

    wakeup(widget)
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to write (save) the widget configuration.
local function write(widget)
    local debug = wHelper.Debug:new(widget.no, "write")
    wStorage.init({ storage = storage, widget = widget })

    -- write widget version number for user data format
    local versionNumber = wHelper.versionStringToNumber(WIDGET_VERSION)
    debug:info(string.format("store version %s (%d)", WIDGET_VERSION, versionNumber))
    storage.write("Version", versionNumber)

    -- widget
    wStorage.write("widgetFontSizeIndex")
    wStorage.write("flightModeNumberShow")
    for i = 1, MAX_FLIGHT_MODES do
        storage.write("FlightModeBgColor" .. i, widget.flightModeColors[i].bgColor)
        storage.write("FlightModeTxColor" .. i, widget.flightModeColors[i].txColor)
    end

    -- title
    wStorage.write("titleShow")
    wStorage.write("titleColorUse")
    wStorage.write("titleBgColor")
    wStorage.write("titleTxColor")

    debug:info("widget data write successfully")
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to read (load) the widget configuration.
local function read(widget)
    local debug = wHelper.Debug:new(widget.no, "read"):info()
    wStorage.init({ storage = storage, widget = widget })

    -- check first field Version number
    local versionNumber = storage.read("Version")
    if not wHelper.isValidVersion(versionNumber) then return end

    --  widget
    wStorage.read("widgetFontSizeIndex")
    wStorage.read("flightModeNumberShow")
    for i = 1, MAX_FLIGHT_MODES do
        widget.flightModeColors[i].bgColor = storage.read("FlightModeBgColor" .. i)
        widget.flightModeColors[i].txColor = storage.read("FlightModeTxColor" .. i)
    end

    -- title
    wStorage.read("titleShow")
    wStorage.read("titleColorUse")
    wStorage.read("titleBgColor")
    wStorage.read("titleTxColor")

    debug:info("widget data read successfully")
end

------------------------------------------------------------------------------------------------------------------------
--- Initialize the widget (register it in the system).
local function init()
    wHelper.Debug:new(0, "init")
    system.registerWidget({
        key = WIDGET_KEY,
        name = name,
        wakeup = wakeup,
        create = create,
        paint = paint,
        configure = configure,
        read = read,
        write = write,
        title = false
    })
end

------------------------------------------------------------------------------------------------------------------------
--- Module main
------------------------------------------------------------------------------------------------------------------------

warn("@on")
initLibraries()

return { init = init }
