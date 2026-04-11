-- test_nav_script.lua
-- Tests Copter Lua scripting API coverage:
--   register_custom_mode()
--   get_circle_radius()
--   set_circle_rate()
--   set_desired_speed()
--   nav_scripting_enable()
--   nav_script_time()
--   nav_script_time_done()

local TEST_INTERVAL_MS = 2000
local last_run = 0
local step = 0
local test_done = false

local function log(msg)
    gcs:send_text(6, "[LuaTest] " .. msg)
end

function update()
    local now = millis()
    if now - last_run < TEST_INTERVAL_MS then
        return update, TEST_INTERVAL_MS
    end
    last_run = now

    if step == 0 then
        log("Starting test_nav_script sequence")
        step = 1

    elseif step == 1 then
        -- ✅ Test register_custom_mode()
        log("Testing register_custom_mode()...")
        local mode_num = 91
        local full_name = "TESTMODE"
        local short_name = "TST"
        local mode_state = vehicle:register_custom_mode(mode_num, full_name, short_name)
        if mode_state then
            log("Custom mode registered successfully")
        else
            log("Custom mode registration failed or already exists")
        end
        step = 2

    elseif step == 2 then
        -- ✅ Test circle mode functions
        log("Testing circle mode functions...")
        local radius = vehicle:get_circle_radius()   -- FIXED: no argument
        if radius then
            log(string.format("Circle radius: %.2f m", radius))
        else
            log("Failed to get circle radius")
        end

        if vehicle:set_circle_rate(25.0) then
            log("Circle rate set to 25 deg/s")
        else
            log("Failed to set circle rate")
        end
        step = 3

    elseif step == 3 then
        -- ✅ Test set_desired_speed()
        log("Testing set_desired_speed()...")
        if vehicle:set_desired_speed(5.0) then
            log("Desired speed set to 5.0 m/s")
        else
            log("Failed to set desired speed")
        end
        step = 4

    elseif step == 4 then
        -- ✅ Test nav_scripting_enable()
        log("Testing nav_scripting_enable()...")
        local auto_mode_num = 3  -- AUTO mode
        if vehicle:nav_scripting_enable(auto_mode_num) then
            log("NAV_SCRIPT_TIME enabled in AUTO")
        else
            log("NAV_SCRIPT_TIME not enabled (not AUTO)")
        end
        step = 5

    elseif step == 5 then
        -- ✅ Test nav_script_time() and nav_script_time_done()
        log("Testing nav_script_time()...")
        local id, cmd, arg1, arg2, arg3, arg4 = vehicle:nav_script_time()
        if id then
            log(string.format("nav_script_time -> id:%d cmd:%d", id, cmd))
            vehicle:nav_script_time_done(id)
            log("nav_script_time_done() called")
        else
            log("nav_script_time() failed or not in AUTO mode")
        end
        step = 6

    elseif step == 6 then
        log("✅ All tests complete")
        test_done = true
        return
    end

    return update, TEST_INTERVAL_MS
end

return update()
