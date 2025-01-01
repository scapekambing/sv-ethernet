#include <cstdint>
#include <WinSock2.h>

#pragma once

#define len 1024 // send 8 bytes of data

namespace sv_ethernet 
{
    class ledCtrl
    {
        private:
            uint8_t num_leds;
            void set_num_leds(char *n);

        public:
            char pkt[len];
            uint8_t disconnect(void);
            uint8_t conn(void);
            uint8_t write_num_leds(char *n);
            uint8_t get_num_leds(void);
            SOCKET s;
            sockaddr_in dest;
            ledCtrl() : num_leds(0), pkt("0"){}

    };
}; // namespace sv_ethernet
