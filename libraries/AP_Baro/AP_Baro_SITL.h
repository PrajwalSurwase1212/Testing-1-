#pragma once

#include "AP_Baro_Backend.h"

#if AP_SIM_BARO_ENABLED

#include <AP_Math/vectorN.h>

#include <SITL/SITL.h>

class AP_Baro_SITL : public AP_Baro_Backend {
public:
    AP_Baro_SITL(AP_Baro &);

    void update() override;

    // adjust for simulated board temperature
    static void temperature_adjustment(float &p, float &T);

    // adjust for wind effects
    static float wind_pressure_correction(uint8_t instance);

protected:

    void update_healthy_flag(uint8_t instance) override { _frontend.sensors[instance].healthy = healthy(instance); };

private:
    uint8_t _instance = 0;
    SITL::SIM *_sitl = nullptr;

    // barometer delay buffer variables
    struct readings_baro {
        uint32_t time;
        float data;
    };
    uint8_t _store_index = 0;
    uint32_t _last_store_time = 0;
    static const uint8_t _buffer_length = 50;
    VectorN<readings_baro, _buffer_length> _buffer;

    // is the barometer usable for flight 
    bool healthy(uint8_t instance);
    
    void _timer();
    bool _has_sample = false;
    uint32_t _last_sample_time = 0;
    float _recent_temp = 0.0f;
    float _recent_press = 0.0f;
    float _last_altitude = 0.0f;

    uint32_t last_drift_delta_t_ms = 0;  // allows for integration of drift over time
    float total_alt_drift = 0.0f;  // integrated altitude drift in metres
};
#endif  // AP_SIM_BARO_ENABLED
