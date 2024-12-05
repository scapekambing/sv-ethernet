#include <stdio.h>
#include <string>
#include <WinSock2.h>
#include <Ws2tcpip.h>

#define len 1024

int main() {
     char pkt[len] = "\0";
     char buffer[len] = "\0";
     sockaddr_in dest;
     WSAData data;
     WSAStartup(MAKEWORD(2, 2), &data);

     int size = sizeof(dest);

     dest.sin_family = AF_INET;
     dest.sin_addr.s_addr = inet_addr("127.0.0.1");
     dest.sin_port = htons(1234);

     // create the socket object
     SOCKET s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

     // connect to the server
     connect(s, (sockaddr *)&dest, sizeof(dest));

     // send the pkt
     while (true) {
          memset(pkt, 0, sizeof(pkt));
          
          printf("Enter a string: ");
          if (fgets(pkt, sizeof(pkt), stdin) != NULL) {
               printf("You entered: %s", pkt);
          } else {
               printf("Error reading input.");
               break;
          }
          pkt[strcspn(pkt, "\n")] = '\0';

          int ret = sendto(s, pkt, strlen(pkt), 0, (sockaddr *)NULL, sizeof(dest) );
          if (ret == SOCKET_ERROR) {
          printf("Error: %d\n", WSAGetLastError());
          }
          else {
          printf("Sent: %s\n", pkt);
          }
          if (strncmp(pkt, "EXIT", strlen("EXIT")) == 0) {
               strcpy(buffer, "");
               break;
          }

          int ret2 = recvfrom(s, buffer, len, 0, (sockaddr *)&dest, &size);
          printf("Received: %s\n", buffer);
          buffer[ret2] = '\0';
     }

     closesocket(s);
     WSACleanup();

     return 0;
}

