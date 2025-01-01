#include <stdio.h>
#include "led_ctrl.hpp"

uint8_t sv_ethernet::ledCtrl::get_num_leds(void)
{
    return num_leds;
}

void sv_ethernet::ledCtrl::set_num_leds(char *n)
{
    pkt[strcspn(pkt, "\n")] = '\0';
    num_leds = atoi(pkt);

    char pkt_copy[sizeof(pkt)];
    strncpy(pkt_copy, pkt, sizeof(pkt));
    
    // offset by to send pkt as raw hex
    for (int i = 0; i < (int)(strlen(pkt)); i++) {
        pkt[i] = pkt[i] - '0';
    }
    if (pkt[0] == '\0') {
        printf("Sending 0x00\n");
        sendto(s, pkt, strlen(pkt)+1, 0, (sockaddr *)&dest, sizeof(dest));    
    }
    else {
        printf("Sending %s\n", pkt_copy);
        sendto(s, pkt, strlen(pkt), 0, (sockaddr *)&dest, sizeof(dest));    
    }
}

uint8_t sv_ethernet::ledCtrl::write_num_leds(char *n)
{
    set_num_leds(n);
    return 1; 
}

uint8_t sv_ethernet::ledCtrl::conn(void)
{
    WSAData data;
    WSAStartup(MAKEWORD(2, 2), &data);
    
    dest.sin_family = AF_INET;
    dest.sin_addr.s_addr = inet_addr("192.168.1.128");
    dest.sin_port = htons(1234);

    // create the socket object
    s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

    // connect to the server
    connect(s, (sockaddr *)&dest, sizeof(dest));
    printf("Connected to server.\n");
    memset(pkt, 0, sizeof(pkt));

    return 1;
}

uint8_t sv_ethernet::ledCtrl::disconnect(void)
{
    closesocket(s);
    WSACleanup();
    return 1;
}

int main()
{

    sv_ethernet::ledCtrl led;
    led.conn();

    while (true) {
        
        printf("Enter a string: ");
        if (fgets(led.pkt, sizeof(led.pkt), stdin) != NULL) {
            printf("Entered: %s\n", led.pkt);
            if (strncmp(led.pkt, "EXIT", strlen("EXIT")) == 0) {
                printf("Exiting...\n");
                break;
            }
            if (led.write_num_leds(led.pkt)) {
                printf("Number of LEDs: %d\n", led.get_num_leds());
            }
            else {
                printf("Error writing number of LEDs.\n");
            }
        } else {
            printf("Error reading input.");
            break;
        }
     }

    led.disconnect();



    return 0;
}
