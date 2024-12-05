#include <stdio.h>
#include "led_ctrl.hpp"

uint8_t sv_ethernet::ledCtrl::get_num_leds(void)
{
    return num_leds;
}

void sv_ethernet::ledCtrl::set_num_leds(uint8_t n)
{
    num_leds = n;
    sprintf(pkt, "%d", num_leds);

    // https://stackoverflow.com/questions/5029840/convert-char-to-int-in-c-and-c

    printf("Number of LEDs set to: %s\n", pkt);
    sendto(s, "TEST", sizeof("TEST"), 0, (sockaddr *)&dest, sizeof(dest));
}

uint8_t sv_ethernet::ledCtrl::write_num_leds(uint8_t n)
{
    set_num_leds(n);
    return 1; 
}

uint8_t sv_ethernet::ledCtrl::conn(void)
{
    WSAData data;
    WSAStartup(MAKEWORD(2, 2), &data);
    
    dest.sin_family = AF_INET;
    dest.sin_addr.s_addr = inet_addr("127.0.0.1");
    dest.sin_port = htons(1234);

    // create the socket object
    s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

    // connect to the server
    connect(s, (sockaddr *)&dest, sizeof(dest));
    printf("Connected to server.\n");
    memset(pkt, 0, sizeof(pkt));
    sendto(s, "ECHO", sizeof("ECHO"), 0, (sockaddr *)NULL, sizeof(dest));

    return 1;
}

uint8_t sv_ethernet::ledCtrl::disconnect(void)
{
    closesocket(s);
    WSACleanup();
    return 1;
}

#define len 1024

int main()
{

    sv_ethernet::ledCtrl led;
    led.conn();

    while (true) {
        
        printf("Enter a string: ");
        if (fgets(led.pkt, sizeof(led.pkt), stdin) != NULL) {
            printf("You entered: %s", led.pkt);
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
        led.pkt[strcspn(led.pkt, "\n")] = '\0';
     }

    led.disconnect();



    return 0;
}