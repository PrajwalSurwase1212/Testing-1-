#pragma once

#include "AP_Baro_Backend.h"

#if AP_BARO_AUAV_ENABLED

#include <AP_HAL/AP_HAL.h>
#include <AP_HAL/Device.h>
#include <AP_HAL/utility/OwnPtr.h>

// Baro uses the airspeed AUAV Pressure sensor class from airspeed, airspeed must be enabled
#include <AP_Airspeed/AP_Airspeed_config.h>
#if !AP_AIRSPEED_AUAV_ENABLED
#error AUAV Baro requires AUAV Airspeed
#endif

#include <AP_Airspeed/AP_Airspeed_AUAV.h>


#ifndef HAL_BARO_AUAV_I2C_ADDR
 #define HAL_BARO_AUAV_I2C_ADDR 0x27
#endif

class AP_Baro_AUAV : public AP_Baro_Backend {
public:
    AP_Baro_AUAV(AP_Baro &baro, AP_HAL::OwnPtr<AP_HAL::Device> dev);

    void update() override;

    static AP_Baro_Backend *probe(AP_Baro &baro, AP_HAL::OwnPtr<AP_HAL::Device> dev);

protected:
    bool init();

    void timer();

    AP_HAL::OwnPtr<AP_HAL::Device> dev;
    AP_HAL::I2CDevice *i2c_dev = nullptr;

    AUAV_Pressure_sensor sensor { i2c_dev, AUAV_Pressure_sensor::Type::Absolute };

    uint8_t instance = 0;

    uint32_t count = 0;
    float pressure_sum = 0.0f;
    float temperature_sum = 0.0f;

    bool measurement_requested = false;
};

#endif  // AP_BARO_AUAV_ENABLED
