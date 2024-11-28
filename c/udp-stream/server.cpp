#include <stdio.h>
#include <string>
#include <WinSock2.h>
#include <Ws2tcpip.h>


#pragma comment(lib, "ws2_32.lib")

#define len 1024

int main() {
     char pkt[len] = "Hello, World!";
     char buffer[len] = "";
     size_t pkt_length = strlen(pkt);
     sockaddr_in dest, surc;
     WSAData data;
     WSAStartup(MAKEWORD(2, 2), &data);

     int size = sizeof(dest);


     // local.sin_family = AF_INET;
     // local.sin_addr.s_addr = inet_addr("127.0.0.1");
     // local.sin_port = 1234; // choose any

     dest.sin_family = AF_INET;
     dest.sin_addr.s_addr = inet_addr("127.0.0.1");
     dest.sin_port = htons(1234);

     // create the socket
     SOCKET s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
     // bind to the local address
     bind(s, (sockaddr *)&dest, sizeof(dest));
     // getsockname(s, (struct sockaddr *)&dest, &size);
     // connect(s, (sockaddr *)&dest, sizeof(dest));

     // send the pkt
     buffer[0] = '\0';
     while (true) {
          int ret2 = recvfrom(s, buffer, len, 0, (sockaddr *)&surc, &size);
          printf("Received: %s\n", buffer);
          buffer[ret2] = '\0';
          if (strncmp(buffer, "EXIT", strlen("EXIT")) == 0) {
               break;
          }
          if (strncmp(buffer, "ACK", strlen("ACK")) == 0) {
               sendto(s, buffer, ret2, 0, (sockaddr *)&surc, size);
               printf("Sent: %s\n", buffer);
               break;
          };
          if (strncmp(buffer, "ECHO", strlen("ECHO")) == 0) {
               while (true) {
                    sendto(s, buffer, ret2, 0, (sockaddr *)&surc, size);
                    printf("Sent: %s\n", buffer);

                    int ret3 = recvfrom(s, buffer, len, 0, (sockaddr *)&surc, &size);
                    printf("Received: %s\n", buffer);
                    buffer[ret3] = '\0';
                    if (strncmp(buffer, "EXIT", strlen("EXIT")) == 0) {
                         break;
                    }
               }
          }

     closesocket(s);
     WSACleanup();

     return 0;
}
}

