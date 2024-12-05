#include <cstdint>
#include <WinSock2.h>

#pragma once

namespace sv_ethernet 
{
    class ledCtrl
    {
        private:
            uint8_t num_leds;
            void set_num_leds(uint8_t n);

        public:
            char pkt[1024] = "\0";
            uint8_t disconnect(void);
            uint8_t conn(void);
            uint8_t write_num_leds(uint8_t n);
            uint8_t get_num_leds(void);
            SOCKET s;
            sockaddr_in dest;
            ledCtrl() : num_leds(0), pkt("\0") {}

    };
}; // namespace sv_ethernet
