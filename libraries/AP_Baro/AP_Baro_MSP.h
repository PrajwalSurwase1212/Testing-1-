/*
  MSP backend barometer
 */
#pragma once

#include "AP_Baro_Backend.h"

// AP_BARO_MSP_ENABLED is defined in AP_Baro.h

#if AP_BARO_MSP_ENABLED

#define MOVING_AVERAGE_WEIGHT 0.20f // a 5 samples moving average

class AP_Baro_MSP : public AP_Baro_Backend
{
public:
    AP_Baro_MSP(AP_Baro &baro, uint8_t msp_instance);
    void update(void) override;
    void handle_msp(const MSP::msp_baro_data_message_t &pkt) override;

private:
    uint8_t instance = 0;
    uint8_t msp_instance = 0;
    float sum_pressure = 0.0f;
    float sum_temp = 0.0f;
    uint16_t count = 0;
};

#endif // AP_BARO_MSP_ENABLED
