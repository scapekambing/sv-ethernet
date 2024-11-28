import socket
import argparse

class Server:
  def __init__(self, ip, port):
    self.addr = (ip, port)
    self.ip = ip
    self.port = port
    self.s = None
  
  def begin(self):
    self.s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    self.s.settimeout(20)
    self.s.bind((self.ip, self.port))
    print(f"Server started on {self.ip}:{self.port}")
    while True:
      try: 
        message, addr = self.s.recvfrom(1024)
        print(f"Message received: {message} from {addr}")
        self.on_message(message, addr)
        break
        
      except OSError as e:
        if isinstance(e, socket.timeout):
          print("\nSocket timed out. Server is shutting down...")
          self.s.close()
          break
        if isinstance(e, KeyboardInterrupt):
          print("\nKeyboard interrupt. Server is shutting down...")
          self.s.close()
          break
        else:
          raise
    print("Server is shutting down. Closing socket connection...")
    self.s.close()

  def on_message(self, message, addr):

    cmd = message[0:4]
    if cmd == b"ACK\x00" or cmd == b"ACK":
      self.s.sendto(message, addr)
      print(f"ACK sent to {addr}")
    elif cmd == b"ECHO":
      self.s.sendto(message, addr)
      self.on_echo(addr)
    elif cmd == b"EXIT":
      self.on_exit()
    else:
      print(f"Command not recognized: {cmd}")

  def on_echo(self, addr):
    print("Starting ECHO server...")
    # message, addr = self.s.recvfrom(1024)
    while True:
      message, addr = self.s.recvfrom(1024)
      print(f"Message received: {message} from {addr}")
      if message == b"exit":
        break
      self.s.sendto(message, addr)
      print(f"Message sent: {message}")
    print("ECHO server is shutting down...")

  def on_exit(self):
    print("EXIT command received.")
      

def main(ip, port):
  s = Server(ip, port)
  s.begin()
    
if __name__ == '__main__':
  argparse = argparse.ArgumentParser(description='Socket communication script.')
  argparse.add_argument('--ip', type=str, default='localhost', help='IP address to connect to')
  argparse.add_argument('--port', type=int, default=1234, help='Port to connect to')
  args = argparse.parse_args()

  main(args.ip, args.port)
