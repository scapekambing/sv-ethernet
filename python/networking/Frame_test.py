from scapy.all import *
import socket

UDP_IP = "192.168.1.128"
UDP_PORT = 1234
MESSAGE = b"Hello world!"

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.sendto(MESSAGE, (UDP_IP, UDP_PORT))

sock.bind((UDP_IP, UDP_PORT))

data, addr = sock.recvfrom(16)
print("Recieved message: %s" % data)