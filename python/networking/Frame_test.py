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
        temp_opcode = self.opcode & 0x03
        temp_address = self.address & 0x3FFFFFFF
        temp_data = self.data & 0xFFFFFFFF
        #raw = (temp_opcode << 62) | (temp_address << 32) | temp_data
        return struct.pack('!Q', (temp_opcode << 62) | (temp_address << 32) | temp_data)
    
    def unpack(packed_data):
        raw = struct.unpack('!Q', packed_data)[0]
        opcode = (raw & 0xC000000000000000) >> 62
        address = (raw & 0x3FFFFFFF00000000) >> 32
        data = (raw & 0x00000000FFFFFFFF)
        return opcode, address, data

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
    opcode, address, data = Packet.unpack(received_data)

    if opcode == OP_WRITE_OK:
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

    opcode, address, data = Packet.unpack(received_data)

    if opcode == OP_READ_OK:
        return True
    else:
        return False

if __name__ == "__main__":
    success = read_single(8562, 69696969)
    print(success)