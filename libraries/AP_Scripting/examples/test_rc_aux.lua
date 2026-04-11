--[[
Test script for RC_Channel_Copter.cpp coverage.
Covers:
  - mode_switch_changed()
  - init_aux_function()
  - do_aux_function_change_mode()
  - do_aux_function()
  - in_rc_failsafe()
  - has_valid_input()
  - arming_check_throttle()
  - get_arming_channel()
]]

local last_run = 0
local interval = 2000
local run_once = false

function log(msg)
    gcs:send_text(6, "[RC_TEST] " .. msg)
end

function update()
    local now = millis()
    if now - last_run < interval then
        return
    end
    last_run = now

    if not arming:is_armed() then
        arming:arm()
        log("Arming vehicle...")
        return
    end

    if not run_once then
        log("Starting RC_Channel_Copter test sequence")

        -- 1. Test flight_mode_channel_number
        local fm_chan = rc:get_channel(copter.g.flight_mode_chan:get())
        if fm_chan then
            log("Flight mode channel number: " .. tostring(copter.g.flight_mode_chan:get()))
        end

        -- 2. Simulate mode switch change
        for i = 0, math.min(5, copter.num_flight_modes - 1) do
            log("Changing mode switch position: " .. i)
            copter:mode_switch_changed(i)
        end

        -- 3. Test in_rc_failsafe() and has_valid_input()
        local failsafe_state = rc:in_failsafe()
        log("Failsafe: " .. tostring(failsafe_state))
        log("Has valid input: " .. tostring(rc:has_valid_input()))

        -- 4. Test arming_check_throttle()
        log("Arming throttle check: " .. tostring(rc:arming_check_throttle()))

        -- 5. Test get_arming_channel()
        local arm_ch = rc:get_channel(copter:get_arming_channel():ch_num())
        log("Arming channel: " .. tostring(arm_ch:ch_num()))

        -- 6. Test init_aux_function()
        rc:init_aux_function(1, 0)
        rc:init_aux_function(70, 1) -- random AUX_FUNC value

        -- 7. Simulate AUX functions (SAVE_WP, RANGEFINDER)
        local trigger = {}
        trigger.func = 50  -- SAVE_WP
        trigger.pos = 2    -- HIGH
        rc:do_aux_function(trigger)

        trigger.func = 73  -- RANGEFINDER
        trigger.pos = 2
        rc:do_aux_function(trigger)

        -- 8. Test mode change through aux
        rc:do_aux_function_change_mode(4, 2)

        log("RC Channel Copter test sequence completed")
        run_once = true
    end
    return update, 1000
end

update()