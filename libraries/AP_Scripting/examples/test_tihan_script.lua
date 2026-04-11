-- Lua script to test all Copter::set_target_* functions (except set_target_location)
-- Intended for code coverage validation under AP_SCRIPTING_ENABLED
--
-- When RC channel 7 > 1800:
--   1. Switch to GUIDED mode
--   2. Execute start_takeoff()
--   3. Execute set_target_pos_NED()
--   4. Execute set_target_posvel_NED()
--   5. Execute set_target_posvelaccel_NED()
--   6. Execute set_target_velocity_NED()
--   7. Execute set_target_velaccel_NED()
--   8. Switch to LAND after 15 seconds

local copter_guided_mode_num = 4
local copter_land_mode_num = 9

local test_started = false
local step = 0
local start_time = 0

-- ✅ Correct Vector3f initialization (no constructor arguments)
local target_pos_ned = Vector3f()
target_pos_ned:x(5)
target_pos_ned:y(5)
target_pos_ned:z(-5)  -- climb 5m (Down is negative)

local target_vel_ned = Vector3f()
target_vel_ned:x(1.0)
target_vel_ned:y(0.5)
target_vel_ned:z(0.0)

local target_accel_ned = Vector3f()
target_accel_ned:x(0.1)
target_accel_ned:y(0.1)
target_accel_ned:z(0.0)

local takeoff_alt = 10 -- meters

function update()
  if not arming:is_armed() then
    test_started = false
    step = 0
  else
    local pwm7 = rc:get_pwm(7)
    if pwm7 and pwm7 > 1800 then
      local mode = vehicle:get_mode()

      -- STEP 0: Switch to GUIDED mode
      if not test_started then
        if mode ~= copter_guided_mode_num then
          vehicle:set_mode(copter_guided_mode_num)
          gcs:send_text(6, "TEST: Switching to GUIDED mode")
        else
          test_started = true
          step = 1
          start_time = millis():toint()
          gcs:send_text(6, "TEST: GUIDED mode active, starting tests")
        end
      end

      -- STEP 1: start_takeoff()
      if test_started and step == 1 then
        local success = vehicle:start_takeoff(takeoff_alt)
        if success then
          gcs:send_text(6, "TEST: start_takeoff(" .. takeoff_alt .. "m) executed successfully")
        else
          gcs:send_text(6, "TEST: start_takeoff() failed")
        end
        step = 2
      end

      -- STEP 2: set_target_pos_NED()
      if step == 2 and (millis():toint() - start_time > 3000) then
        local success = vehicle:set_target_pos_NED(target_pos_ned, true, 45, false, 0, false, false)
        gcs:send_text(6, success and "TEST: set_target_pos_NED() executed successfully" or "TEST: set_target_pos_NED() failed")
        step = 3
      end

      -- STEP 3: set_target_posvel_NED()
      if step == 3 and (millis():toint() - start_time > 6000) then
        local success = vehicle:set_target_posvel_NED(target_pos_ned, target_vel_ned)
        gcs:send_text(6, success and "TEST: set_target_posvel_NED() executed successfully" or "TEST: set_target_posvel_NED() failed")
        step = 4
      end

      -- STEP 4: set_target_posvelaccel_NED()
      if step == 4 and (millis():toint() - start_time > 9000) then
        local success = vehicle:set_target_posvelaccel_NED(target_pos_ned, target_vel_ned, target_accel_ned, true, 90, false, 0, false)
        gcs:send_text(6, success and "TEST: set_target_posvelaccel_NED() executed successfully" or "TEST: set_target_posvelaccel_NED() failed")
        step = 5
      end

      -- STEP 5: set_target_velocity_NED()
      if step == 5 and (millis():toint() - start_time > 12000) then
        local success = vehicle:set_target_velocity_NED(target_vel_ned)
        gcs:send_text(6, success and "TEST: set_target_velocity_NED() executed successfully" or "TEST: set_target_velocity_NED() failed")
        step = 6
      end

      -- STEP 6: set_target_velaccel_NED()
      if step == 6 and (millis():toint() - start_time > 14000) then
        local success = vehicle:set_target_velaccel_NED(target_vel_ned, target_accel_ned, true, 30, false, 0, false)
        gcs:send_text(6, success and "TEST: set_target_velaccel_NED() executed successfully" or "TEST: set_target_velaccel_NED() failed")
        step = 7
      end

      -- STEP 7: Switch to LAND
      if step == 7 and (millis():toint() - start_time > 16000) then
        vehicle:set_mode(copter_land_mode_num)
        gcs:send_text(6, "TEST COMPLETE: Switching to LAND mode")
        step = 8
      end
    end
  end

  return update, 1000
end

return update()
