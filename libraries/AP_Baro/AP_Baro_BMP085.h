#pragma once

#include "AP_Baro_Backend.h"

#if AP_BARO_BMP085_ENABLED

#include <AP_HAL/AP_HAL.h>
#include <AP_HAL/I2CDevice.h>
#include <AP_HAL/utility/OwnPtr.h>
#include <Filter/Filter.h>

#ifndef HAL_BARO_BMP085_I2C_ADDR
#define HAL_BARO_BMP085_I2C_ADDR        (0x77)
#endif

class AP_Baro_BMP085 : public AP_Baro_Backend {
public:
    AP_Baro_BMP085(AP_Baro &baro, AP_HAL::OwnPtr<AP_HAL::Device> dev);

    /* AP_Baro public interface: */
    void update() override;

    static AP_Baro_Backend *probe(AP_Baro &baro, AP_HAL::OwnPtr<AP_HAL::Device> dev);


private:
    bool _init();

    void _cmd_read_pressure();
    void _cmd_read_temp();
    bool _read_pressure();
    void _read_temp();
    void _calculate();
    bool _data_ready();

    void _timer(void);

    uint16_t _read_prom_word(uint8_t word);
    bool     _read_prom(uint16_t *prom);


    AP_HAL::OwnPtr<AP_HAL::Device> _dev;
    AP_HAL::DigitalSource *_eoc = nullptr;

    uint8_t _instance = 0;
    bool _has_sample = false;

    // Boards with no EOC pin: use times instead
    uint32_t _last_press_read_command_time = 0;
    uint32_t _last_temp_read_command_time = 0;

    // State machine
    uint8_t _state = 0;

    // Internal calibration registers
    int16_t ac1 = 0, ac2 = 0, ac3 = 0, b1 = 0, b2 = 0, mb = 0, mc = 0, md = 0;
    uint16_t ac4 = 0, ac5 = 0, ac6 = 0;

    int32_t _raw_pressure = 0;
    int32_t _raw_temp = 0;
    int32_t _temp = 0;
    AverageIntegralFilter<int32_t, int32_t, 10> _pressure_filter;

    uint8_t _vers = 0;
    uint8_t _type = 0;
};

#endif  // AP_BARO_BMP085_ENABLED
