#include <stdio.h>
#include "led_ctrl.hpp"

uint8_t ledCtrl::get_num_leds(void)
{
    return num_leds;
}

void ledCtrl::set_num_leds(uint8_t n)
{
    ledCtrl::num_leds = (n);
}

uint8_t ledCtrl::write_num_leds(uint8_t n)
{
    set_num_leds(n);
    return 1; 
}

uint8_t ledCtrl::connect(void)
{
    sockaddr_in dest;
    WSAData data;
    WSAStartup(MAKEWORD(2, 2), &data);

    dest.sin_family = AF_INET;
    dest.sin_addr.s_addr = inet_addr("127.0.0.1");
    dest.sin_port = htons(1234);

    // create the socket object
    SOCKET s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

    // connect to the server
    connect(s, (sockaddr *)&dest, sizeof(dest));

    memset(pkt, 0, sizeof(pkt));

    return 1;
}

uint8_t ledCtrl::disconnect(void)
{
    closesocket(s);
    WSACleanup();
    return 1;
}

#define len 1024

int main()
{
    ledCtrl led;
    while (true) {
        
        printf("Enter a string: ");
        if (fgets(led.pkt, sizeof(led.pkt), stdin) != NULL) {
            printf("You entered: %s", pkt);
            if (strncmp(led.pkt, "EXIT", strlen("EXIT")) == 0) {
                printf("Exiting...\n");
                break;
            }
            if (led.write_num_leds(atoi(led.pkt))) {
                printf("Number of LEDs: %d\n", led.get_num_leds());
            }
            else {
                printf("Error writing number of LEDs.\n");
            }
        } else {
            printf("Error reading input.");
            break;
        }
        pkt[strcspn(pkt, "\n")] = '\0';
     }

    led.disconnect();



    return 0;
}