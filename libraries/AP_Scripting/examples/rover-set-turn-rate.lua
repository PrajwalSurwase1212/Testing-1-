-- Lua test script for Copter::set_target_rate_and_throttle()
-- Intended for coverage validation under AP_SCRIPTING_ENABLED
-- Author: Tihan Autotest
--
-- When RC channel 7 > 1800:
--   1. Switch to GUIDED mode
--   2. Send multiple rate + throttle commands
--   3. Switch to LAND mode at end

local copter_guided_mode_num = 4
local copter_land_mode_num = 9
local rc_channel_switch = 7

local test_started = false
local step = 0
local start_time = 0

-- Define test inputs
local roll_rate_dps   = 30    -- roll rate in deg/s
local pitch_rate_dps  = -20   -- pitch rate in deg/s
local yaw_rate_dps    = 45    -- yaw rate in deg/s
local throttle_value  = 0.55  -- normalized throttle (0 to 1)

gcs:send_text(6, "TEST: set_target_rate_and_throttle() script loaded")

function update()
    local pwm7 = rc:get_pwm(rc_channel_switch)
    if pwm7 and pwm7 > 1800 then
        local mode = vehicle:get_mode()

        -- STEP 0: Ensure we are in GUIDED mode
        if not test_started then
            if mode ~= copter_guided_mode_num then
                vehicle:set_mode(copter_guided_mode_num)
                gcs:send_text(6, "TEST: Switching to GUIDED mode")
            else
                test_started = true
                step = 1
                start_time = millis():toint()
                gcs:send_text(6, "TEST: GUIDED mode active, starting rate tests")
            end
        end

        -- STEP 1: Send rate/throttle command
        if test_started and step == 1 then
            local success = vehicle:set_target_rate_and_throttle(
                roll_rate_dps,
                pitch_rate_dps,
                yaw_rate_dps,
                throttle_value
            )

            if success then
                gcs:send_text(6, string.format(
                    "TEST: set_target_rate_and_throttle(%.1f, %.1f, %.1f, %.2f) success",
                    roll_rate_dps, pitch_rate_dps, yaw_rate_dps, throttle_value
                ))
            else
                gcs:send_text(6, "TEST: set_target_rate_and_throttle() failed")
            end

            step = 2
        end

        -- STEP 2: Change rates after 3 seconds
        if step == 2 and (millis():toint() - start_time > 3000) then
            local success = vehicle:set_target_rate_and_throttle(
                -roll_rate_dps,
                pitch_rate_dps,
                -yaw_rate_dps,
                throttle_value
            )

            if success then
                gcs:send_text(6, "TEST: Reversed rate command success")
            else
                gcs:send_text(6, "TEST: Reversed rate command failed")
            end

            step = 3
        end

        -- STEP 3: Land after 6 seconds
        if step == 3 and (millis():toint() - start_time > 6000) then
            vehicle:set_mode(copter_land_mode_num)
            gcs:send_text(6, "TEST COMPLETE: Switching to LAND mode")
            step = 4
        end
    end

    return update, 500 -- run every 500 ms
end

return update()
