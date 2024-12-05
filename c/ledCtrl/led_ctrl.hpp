#include <cstdint>
#include <WinSock2.h>

#pragma once

class ledCtrl
{
    private:
        uint8_t num_leds;
        SOCKET s;
        void set_num_leds(uint8_t n);

    public:
        char pkt[1024];
        uint8_t disconnect(void);
        uint8_t connect(void);
        uint8_t write_num_leds(uint8_t n);
        uint8_t get_num_leds(void);
        uint8_t connect(void);
        ledCtrl() : num_leds(0), pkt("\0") {}

};
