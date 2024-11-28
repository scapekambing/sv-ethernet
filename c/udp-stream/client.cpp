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
     sockaddr_in dest;
     sockaddr_in local;
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
     // bind(s, (sockaddr *)&dest, sizeof(local));
     // getsockname(s, (struct sockaddr *)&dest, &size);
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

          int ret = sendto(s, pkt, pkt_length, 0, (sockaddr *)NULL, sizeof(dest) );
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

