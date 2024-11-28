import socket
import argparse

class Client:
  def __init__(self, ip, port, data):
    self.ip = ip
    self.port = port
    self.data = data
    self.s = None
  
  def begin(self):
    self.s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    self.s.settimeout(10)
    self.s.sendto(self.data, (self.ip, self.port))
    print(f"Client sent {self.data} to {self.ip}:{self.port}")
    while True:
      if self.data == b"EXIT":
        break
      try: 
        message, addr = self.s.recvfrom(1024)
        print(f"Message received: {message} from {addr}")
        self.on_message(message, addr)
        break
        
      except OSError as e:
        if isinstance(e, socket.timeout):
          print("\nSocket timed out. Client is shutting down...")
          self.s.close()
          break
        if isinstance(e, KeyboardInterrupt):
          print("\nKeyboard interrupt. Client is shutting down...")
          self.s.close()
          break
        else:
          raise
    print("Client is shutting down. Closing socket connection...")
    self.s.close()

  def on_message(self, message, addr):
    print("Message received: ", message)
    cmd = message[0:4]
    if cmd == b"ACK\x00":
      self.on_ack(addr)
    elif cmd == b"ECHO":
      self.on_echo(addr)
    else:
      print("message received: ", message)

  def on_ack(self, addr):
    print("\033[92m ACK \033[0m", "| from: ", addr)

  def on_echo(self, addr):
    print("ECHO server started. Type 'exit' to exit.")
    send_message = input("Enter message: ")
    self.s.sendto(bytes(send_message, "utf-8"), addr)
    while True:
      if send_message == "exit":
        break
      else:
        recv_message, addr = self.s.recvfrom(1024)
        if recv_message:
          print(f"Message received: {recv_message} from {addr}")
          send_message = input("Enter message: ")
          self.s.sendto(bytes(send_message, "utf-8"), addr)
    

def main(ip, port, data):
  c = Client(ip, port, data)
  c.begin()
  
if __name__ == '__main__':
  argparse = argparse.ArgumentParser(description='Socket communication script.')
  argparse.add_argument('--ip', type=str, default='localhost', help='IP address to connect to')
  argparse.add_argument('--port', type=int, default=1234, help='Port to connect to')
  argparse.add_argument('--data', type=str, default="ACK", help='Data to send')
  args = argparse.parse_args()
  main(args.ip, args.port, bytes(args.data, "utf-8"))