--[[
    test_aux_func.lua
    Purpose: Test mode switching and auxiliary function handling
    in SITL or scripting environment for Copter.

    Covers:
      - AUX switch functions (LAND, GUIDED, RTL)
      - Mode switching via RC channels
      - set_rc(), vehicle:get_mode(), vehicle:set_mode(), millis(), etc.
]]

local test_start_ms = 0
local test_stage = 0
local update_interval = 2000  -- 2 seconds between updates
local test_done = false

-- Mode numbers from ArduPilot/Copter
local mode_circle = 3
local mode_land = 9
local mode_guided = 4
local mode_rtl = 6
local mode_loiter = 5

-- Ensure AuxSwitchPos exists (some SITL builds may not have it)
if not AuxSwitchPos then
    AuxSwitchPos = { LOW = 0, MIDDLE = 1, HIGH = 2 }
end

function start_test()
    gcs:send_text(6, "Starting AUX function test...")
    test_start_ms = millis()

    -- Example setup
    param:set("RC9_OPTION", 18)   -- LAND
    param:set("RC10_OPTION", 55)  -- GUIDED
    param:set("RC11_OPTION", 20)  -- RTL
    param:set("FLTMODE_CH", 5)    -- mode switch

    gcs:send_text(6, "Parameters configured")
end

function run_test()
    local now = millis()
    if test_done then
        return update, update_interval
    end

    if now - test_start_ms < 3000 then
        return update, update_interval
    end

    if test_stage == 0 then
        gcs:send_text(6, "Stage 0: Forcing CIRCLE mode")
        vehicle:set_mode(mode_circle)
        test_stage = 1

    elseif test_stage == 1 then
        if vehicle:get_mode() == mode_circle then
            gcs:send_text(6, "Stage 1: Switching RC9 (LAND)")
            rc:set_aux_switch(9, AuxSwitchPos.HIGH)
            test_stage = 2
        end

    elseif test_stage == 2 then
        if vehicle:get_mode() == mode_land then
            gcs:send_text(6, "Stage 2: Switching RC10 (GUIDED)")
            rc:set_aux_switch(10, AuxSwitchPos.HIGH)
            test_stage = 3
        end

    elseif test_stage == 3 then
        if vehicle:get_mode() == mode_guided then
            gcs:send_text(6, "Stage 3: Switching RC11 (RTL)")
            rc:set_aux_switch(11, AuxSwitchPos.HIGH)
            test_stage = 4
        end

    elseif test_stage == 4 then
        if vehicle:get_mode() == mode_rtl then
            gcs:send_text(6, "Stage 4: Resetting RC10 low to return to CIRCLE")
            rc:set_aux_switch(10, AuxSwitchPos.LOW)
            test_stage = 5
        end

    elseif test_stage == 5 then
        if vehicle:get_mode() == mode_circle then
            gcs:send_text(6, "All AUX function mode transitions successful.")
            test_done = true
        end
    end

    return update, update_interval
end

function update()
    if test_start_ms == 0 then
        start_test()
    end
    return run_test()
end

update()