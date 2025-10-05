------------------------------------------------------------------------------------------------------------------------
---  Widget Storage Functions
------------------------------------------------------------------------------------------------------------------------
---
---  wStorage library with functions for widget configuration:
---
---    init(parameters)
---    write(key)
---    read(key)
---    return function(parameters)
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

-- library structure
local wStorage = {}

-- parameters
local storage = {} -- storage structure, for read/write functions
local widget  = {} -- widget  structure

--  required libraries
local wHelper = {} -- helper library

-- config parameters
local CFL     = {} -- capitalize first letter function

-- local variables
local line    = {} -- form line

-----------------------------------------------------------------------------------------------------------------------
--- Init with actual form and widget
function wStorage.init(parameters)
    storage = parameters.storage
    widget = parameters.widget
end

------------------------------------------------------------------------------------------------------------------------
--- Write widget config element to storage.
function wStorage.write(key)
    storage.write(CFL(key), widget[key])
end

------------------------------------------------------------------------------------------------------------------------
--- Read widget config element to storage.
function wStorage.read(key)
    widget[key] = storage.read(CFL(key))
end

-----------------------------------------------------------------------------------------------------------------------
--- Library settings and export
return function(parameters)
    wHelper = parameters.wHelper
    CFL = wHelper.capitalizeFirstLetter

    return wStorage
end
