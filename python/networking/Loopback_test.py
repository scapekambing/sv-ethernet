import socket

UDP_IP = "192.168.1.128"
UDP_PORT = 1234

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

#sock.bind(("192.168.1.2", 1234))

message = "Hello, world!\n"

sock.sendto(b'Hello, world!\n', (UDP_IP, UDP_PORT))