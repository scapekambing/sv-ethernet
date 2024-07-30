from scapy.all import *
import struct
import socket

OP_WRITE_DATA = 0
OP_READ_DATA = 1
OP_WRITE_OK = 2
OP_READ_OK = 3

UDP_IP = "192.168.1.128" # The IP address of the FPGA
UDP_PORT = 1234

class Packet:
    def __init__(self, opcode, address, data):
        self.opcode = opcode
        self.address = address
        self.data = data
    
    def pack(self):
        return struct.pack('!HLL', self.opcode, self.address, self.data)
    
    def unpack(cls, packed_data):
        opcode, address, data = struct.unpack('!HLL', packed_data)
        return cls(opcode, address, data)

def write_single(address, data):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    #sock.setsockopt(socket.SOL_SOCKET, 25, str("Ethernet 2" + '\0').encode('utf-8'))

    #sock.bind(("192.168.1.2", 1234))
    #print(f"Socket bound to: {sock.getsockname()}")

    packet = Packet(OP_WRITE_DATA, address, data)

    print("Created packet, sending")
    sock.sendto(packet.pack(), (UDP_IP, UDP_PORT))

    print("Sent packet, receiving")
    received_data = sock.recv(8)
    packet = Packet.unpack(received_data)

    if packet.opcode == OP_WRITE_OK:
        return True
    else:
        return False
    
def read_single(address, data):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    #sock.setsockopt(socket.SOL_SOCKET, 25, str("Ethernet 2" + '\0').encode('utf-8'))

    #sock.bind(("192.168.1.2", 1234))
    #print(f"Socket bound to: {sock.getsockname()}")

    packet = Packet(OP_READ_DATA, address, data)

    print("Created packet, sending")
    sock.sendto(packet.pack(), (UDP_IP, UDP_PORT))

    print("Sent packet, receiving")
    received_data = sock.recv(8)
    packet = Packet.unpack(received_data)

    if packet.opcode == OP_WRITE_OK:
        return True
    else:
        return False

if __name__ == "__main__":
    success = read_single(8562, 69696969)
    print(success)