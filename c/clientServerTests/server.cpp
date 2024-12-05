#include <stdio.h>
#include <string>
#include <WinSock2.h>
#include <Ws2tcpip.h>

#define len 1024

int main() {
     char buffer[len] = "\0";
     sockaddr_in dest, surc;
     WSAData data;
     WSAStartup(MAKEWORD(2, 2), &data);

     int size = sizeof(dest);
     int ret;

     dest.sin_family = AF_INET;
     dest.sin_addr.s_addr = inet_addr("127.0.0.1");
     dest.sin_port = htons(1234);

     // create the socket object
     SOCKET s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
     // bind to socket
     bind(s, (sockaddr *)&dest, sizeof(dest));

     // send the pkt
     while (true) {
          ret = recvfrom(s, buffer, len, 0, (sockaddr *)&surc, &size);
          printf("Received: %s\n", buffer);
          buffer[ret] = '\0';
          if (strncmp(buffer, "EXIT", strlen("EXIT")) == 0) {
               break;
          }
          else if (strncmp(buffer, "ACK", strlen("ACK")) == 0) {
               sendto(s, buffer, ret, 0, (sockaddr *)&surc, size);
               printf("Sent: %s\n", buffer);
               break;
          }
          else if (strncmp(buffer, "ECHO", strlen("ECHO")) == 0) {
               while (true) {
                    sendto(s, buffer, ret, 0, (sockaddr *)&surc, size);
                    printf("Sent: %s\n", buffer);

                    ret = recvfrom(s, buffer, len, 0, (sockaddr *)&surc, &size);
                    printf("Received: %s\n", buffer);
                    buffer[ret] = '\0';
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

