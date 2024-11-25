import socket
import argparse

def on_message(message):
  if message == b"ACK":
    print("\033[92m ACK \033[0m", "| message received: ", message)
  else:
    print("message received: ", message) 

def main(ip, port, data, _on_message=None):
  s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  s.settimeout(10)
  s.sendto(data, (ip, port))
  print(f"Data sent: {data}")
  while True:
    message, addr = s.recvfrom(1024)
    if message:
      _on_message(message)
      break
  s.close()
  
if __name__ == '__main__':
  argparse = argparse.ArgumentParser(description='Socket communication script.')
  argparse.add_argument('--ip', type=str, default='localhost', help='IP address to connect to')
  argparse.add_argument('--port', type=int, default=1234, help='Port to connect to')
  argparse.add_argument('--data', type=str, default="ACK", help='Data to send')
  args = argparse.parse_args()
  main(args.ip, args.port, bytes(args.data, "utf-8"), on_message)