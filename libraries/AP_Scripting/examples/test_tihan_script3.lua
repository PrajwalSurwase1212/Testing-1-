-- Lua test script for:
--   has_ekf_failsafed()
--   get_target_location()
--   update_target_location()
--   is_landing()
--   is_taking_off()
--
-- This script is intended for code coverage testing under AP_SCRIPTING_ENABLED
-- When RC channel 7 > 1800:
--   1. Switch to GUIDED mode
--   2. Query EKF failsafe status
--   3. Fetch current target location
--   4. Update target location slightly (to trigger update_target_location)
--   5. Query landing and taking off status

local copter_guided_mode_num = 4
local copter_land_mode_num = 9
local rc_channel_switch = 7

local test_started = false
local step = 0
local start_time = 0

gcs:send_text(6, "TEST: has_ekf_failsafed / get_target_location / update_target_location / is_landing / is_taking_off")

function update()
    local pwm7 = rc:get_pwm(rc_channel_switch)
    if pwm7 and pwm7 > 1800 then
        local mode = vehicle:get_mode()

        -- STEP 0: Ensure in GUIDED mode
        if not test_started then
            if mode ~= copter_guided_mode_num then
                vehicle:set_mode(copter_guided_mode_num)
                gcs:send_text(6, "TEST: Switching to GUIDED mode")
            else
                test_started = true
                step = 1
                start_time = millis():toint()
                gcs:send_text(6, "TEST: GUIDED mode active, starting EKF/target tests")
            end
        end

        -- STEP 1: has_ekf_failsafed()
        if step == 1 then
            local ekf_fail = vehicle:has_ekf_failsafed()
            gcs:send_text(6, "TEST: has_ekf_failsafed() returned " .. tostring(ekf_fail))
            step = 2
        end

        -- STEP 2: get_target_location()
        if step == 2 and (millis():toint() - start_time > 2000) then
            local loc = Location()
            local success = vehicle:get_target_location()
            if success then
                gcs:send_text(6, string.format(
                    "TEST: get_target_location() success: lat=%.7f lon=%.7f alt=%.2f",
                    loc:lat(), loc:lng(), loc:alt()
                ))

                -- Modify location slightly for update test
                loc:set_alt(loc:alt() + 1.0)
                test_loc = loc
            else
                gcs:send_text(6, "TEST: get_target_location() failed")
            end
            step = 3
        end

        -- STEP 3: update_target_location()
        if step == 3 and (millis():toint() - start_time > 4000) then
            if test_loc then
                local old_loc = Location()
                local got_old = vehicle:get_target_location(old_loc)
                if got_old then
                    local updated = vehicle:update_target_location(old_loc, test_loc)
                    gcs:send_text(6, "TEST: update_target_location() returned " .. tostring(updated))
                else
                    gcs:send_text(6, "TEST: Could not get old target location")
                end
            end
            step = 4
        end

        -- STEP 4: is_taking_off() / is_landing()
        if step == 4 and (millis():toint() - start_time > 6000) then
            local taking_off = vehicle:is_taking_off()
            local landing = vehicle:is_landing()
            gcs:send_text(6, "TEST: is_taking_off() = " .. tostring(taking_off))
            gcs:send_text(6, "TEST: is_landing() = " .. tostring(landing))

            gcs:send_text(6, "TEST COMPLETE: EKF + target location helper coverage done")
            step = 5
        end
    end

    return update, 1000
end

return update()
