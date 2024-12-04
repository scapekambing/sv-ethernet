#include <cstdint>

#pragma once

class ledCtrl
{
    private:
        uint8_t num_leds;

    public:
        void set_num_leds(uint8_t n);
        uint8_t get_num_leds(void);
};
