#pragma once

#include "AP_Baro_Backend.h"

#if AP_BARO_BMP280_ENABLED

#include <AP_HAL/AP_HAL.h>
#include <AP_HAL/Device.h>
#include <AP_HAL/utility/OwnPtr.h>

#ifndef HAL_BARO_BMP280_I2C_ADDR
 #define HAL_BARO_BMP280_I2C_ADDR  (0x76)
#endif
#ifndef HAL_BARO_BMP280_I2C_ADDR2
 #define HAL_BARO_BMP280_I2C_ADDR2 (0x77)
#endif

class AP_Baro_BMP280 : public AP_Baro_Backend
{
public:
    AP_Baro_BMP280(AP_Baro &baro, AP_HAL::OwnPtr<AP_HAL::Device> dev);

    /* AP_Baro public interface: */
    void update() override;

    static AP_Baro_Backend *probe(AP_Baro &baro, AP_HAL::OwnPtr<AP_HAL::Device> dev);

private:

    bool _init(void);
    void _timer(void);
    void _update_temperature(int32_t);
    void _update_pressure(int32_t);

    AP_HAL::OwnPtr<AP_HAL::Device> _dev;

    uint8_t _instance = 0;
    int32_t _t_fine = 0;
    float _pressure_sum = 0.0f;
    uint32_t _pressure_count = 0;
    float _temperature = 0.0f;

    // Internal calibration registers
    int16_t _t2 = 0, _t3 = 0, _p2 = 0, _p3 = 0, _p4 = 0, _p5 = 0, _p6 = 0, _p7 = 0, _p8 = 0, _p9 = 0;
    uint16_t _t1 = 0, _p1 = 0;
};

#endif  // AP_BARO_BMP280_ENABLED
