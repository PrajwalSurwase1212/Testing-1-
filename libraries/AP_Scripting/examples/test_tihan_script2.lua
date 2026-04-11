--[[
   Testcase Script for Copter::set_target_angle_and_climbrate(),
   Copter::set_target_rate_and_throttle(),
   and Copter::register_custom_mode()

   Steps:
     1. Switch to GUIDED mode
     2. Arm and takeoff to 5 m
     3. Apply target attitude commands (roll/pitch/yaw)
     4. Apply rate+throttle targets
     5. Register a custom GUIDED mode
     6. Land after 15 seconds
]]

local GUIDED = 4
local LAND = 9
local takeoff_alt = 5
local test_step = 0
local start_time = 0
local mode_registered = false

function update()
    local mode = vehicle:get_mode()

    -- Step 1: switch to GUIDED
    if test_step == 0 then
        gcs:send_text(0, "Switching to GUIDED mode...")
        vehicle:set_mode(GUIDED)
        test_step = 1
        return update, 2000
    end

    -- Step 2: arm and takeoff
    if test_step == 1 and mode == GUIDED then
        if not arming:is_armed() then
            arming:arm()
            gcs:send_text(0, "Arming motors...")
            return update, 2000
        end

        if ahrs:get_home() then
            gcs:send_text(0, "Executing takeoff to " .. tostring(takeoff_alt) .. "m...")
            vehicle:start_takeoff(takeoff_alt)
            start_time = millis()
            test_step = 2
        end
        return update, 2000
    end

    -- Step 3: Apply set_target_angle_and_climbrate()
    if test_step == 2 and (millis() - start_time > 5000) then
        gcs:send_text(0, "Applying target angle and climb rate...")
        local roll = 10     -- deg
        local pitch = 5     -- deg
        local yaw = 45      -- deg
        local climb_rate = 0.5 -- m/s
        local use_yaw_rate = false
        local yaw_rate = 0
        local ok = vehicle:set_target_angle_and_climbrate(roll, pitch, yaw, climb_rate, use_yaw_rate, yaw_rate)
        gcs:send_text(0, "set_target_angle_and_climbrate() -> " .. tostring(ok))
        test_step = 3
        return update, 3000
    end

    -- Step 4: Apply set_target_rate_and_throttle()
    if test_step == 3 then
        gcs:send_text(0, "Applying target rate and throttle...")
        local roll_rate = 10    -- deg/s
        local pitch_rate = 10   -- deg/s
        local yaw_rate = 15     -- deg/s
        local throttle = 0.6    -- 60% throttle
        local ok = vehicle:set_target_rate_and_throttle(roll_rate, pitch_rate, yaw_rate, throttle)
        gcs:send_text(0, "set_target_rate_and_throttle() -> " .. tostring(ok))
        test_step = 4
        return update, 4000
    end

    -- Step 5: Register custom mode (once)
    if test_step == 4 then
        if not mode_registered then
            gcs:send_text(0, "Registering custom guided mode...")
            local custom_state = vehicle:register_custom_mode(100, "TEST_MODE", "TST1")
            if custom_state then
                gcs:send_text(0, "Custom mode registered successfully!")
            else
                gcs:send_text(0, "Custom mode registration failed.")
            end
            mode_registered = true
        end
        test_step = 5
        start_time = millis()
        return update, 1000
    end

    -- Step 6: after 15 seconds -> LAND
    if test_step == 5 and (millis() - start_time > 15000) then
        gcs:send_text(0, "Landing after test...")
        vehicle:set_mode(LAND)
        test_step = 6
        return update, 2000
    end

    -- Step 7: end
    if test_step == 6 then
        if not arming:is_armed() then
            gcs:send_text(0, "Test completed and disarmed.")
            return
        end
        return update, 2000
    end

    return update, 1000
end

return update()