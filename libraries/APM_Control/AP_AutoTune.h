#pragma once

#include <AP_Logger/LogStructure.h>
#include <AP_Param/AP_Param.h>
#include <AP_Vehicle/AP_FixedWing.h>
#include <Filter/SlewLimiter.h>

#include <Filter/ModeFilter.h>

class AP_AutoTune
{
public:
    struct ATGains {
        AP_Float tau;
        AP_Int16 rmax_pos;
        AP_Int16 rmax_neg;
        float FF = 0.0f, P = 0.0f, I = 0.0f, D = 0.0f, IMAX = 0.0f;
        float flt_T = 0.0f, flt_E = 0.0f, flt_D = 0.0f;
    };

    enum ATType {
        AUTOTUNE_ROLL  = 0,
        AUTOTUNE_PITCH = 1,
        AUTOTUNE_YAW = 2,
    };

    enum Options {
        DISABLE_FLTD_UPDATE = 0,
        DISABLE_FLTT_UPDATE = 1
    };

    struct PACKED log_ATRP {
        LOG_PACKET_HEADER;
        uint64_t time_us;
        uint8_t type;
        uint8_t state;
        float actuator;
        float P_slew;
        float D_slew;
        float FF_single;
        float FF;
        float P;
        float I;
        float D;
        uint8_t action;
        float rmax;
        float tau;
    };

    // constructor
    AP_AutoTune(ATGains &_gains, ATType type, const AP_FixedWing &parms, class AC_PID &rpid);

    // called when autotune mode is entered
    void start(void);

    // called to stop autotune and restore gains when user leaves
    // autotune
    void stop(void);

    // update called whenever autotune mode is active. This is
    // called at the main loop rate
    void update(struct AP_PIDInfo &pid_info, float scaler, float angle_err_deg);

    // are we running?
    bool running = false;

    static const char *axis_string(ATType _type);

private:
    // the current gains
    ATGains &current;
    class AC_PID &rpid;

    // what type of autotune is this
    ATType type;

    const AP_FixedWing &aparm;

    // values to restore if we leave autotune mode
    ATGains restore;
    ATGains last_save;

    // last logging time
    uint32_t last_log_ms = 0;

    // the demanded/achieved state
    enum class ATState {IDLE,
                        DEMAND_POS,
                        DEMAND_NEG
                       };
    ATState state = ATState::IDLE;

    // the demanded/achieved state
    enum class Action {NONE,
                       LOW_RATE,
                       SHORT,
                       RAISE_PD,
                       LOWER_PD,
                       IDLE_LOWER_PD,
                       RAISE_D,
                       RAISE_P,
                       LOWER_D,
                       LOWER_P
                      };
    Action action = Action::NONE;

    // when we entered the current state
    uint32_t state_enter_ms = 0;

    void check_state_exit(uint32_t state_time_ms);
    void save_gains(void);

    void save_float_if_changed(AP_Float &v, float value);
    void save_int16_if_changed(AP_Int16 &v, int16_t value);
    void state_change(ATState newstate);
    const char *axis_string(void) const;

    // get gains with PID components
    ATGains get_gains(void);
    void restore_gains(void);

    // update rmax and tau towards target
    void update_rmax();

    bool has_option(Options option) {
        return (aparm.autotune_options.get() & uint32_t(1<<uint32_t(option))) != 0;
    }

    // 5 point mode filter for FF estimate
    ModeFilterFloat_Size5 ff_filter;

    LowPassFilterConstDtFloat actuator_filter;
    LowPassFilterConstDtFloat rate_filter;
    LowPassFilterConstDtFloat target_filter;

    // separate slew limiters for P and D
    float slew_limit_max = 0.0f, slew_limit_tau = 0.0f;
    SlewLimiter slew_limiter_P{slew_limit_max, slew_limit_tau};
    SlewLimiter slew_limiter_D{slew_limit_max, slew_limit_tau};

    float max_actuator = 0.0f;
    float min_actuator = 0.0f;
    float max_rate = 0.0f;
    float min_rate = 0.0f;
    float max_target = 0.0f;
    float min_target = 0.0f;
    float max_P = 0.0f;
    float max_D = 0.0f;
    float min_Dmod = 0.0f;
    float max_Dmod = 0.0f;
    float max_SRate_P = 0.0f;
    float max_SRate_D = 0.0f;
    float FF_single = 0.0f;
    uint16_t ff_count = 0;
    float dt = 0.0f;
    float D_limit = 0.0f;
    float P_limit = 0.0f;
    uint32_t D_set_ms = 0;
    uint32_t P_set_ms = 0;
    uint8_t done_count = 0;
};
