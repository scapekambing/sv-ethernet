import socket
import argparse

def on_message(message):

  
  return 

def main(ip, port):
   s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
   s.settimeout(10)
   s.bind((ip, port))
   
   while True:
    try: 
      message, addr = s.recvfrom(1024)
      print(f"Message received: {message} from {addr}")

      if message:
        s.sendto(message, addr)
        print(f"{str(message)} sent.")
        
    except OSError as e:
      if isinstance(e, socket.timeout):
        print("\nSocket timed out. Server is shutting down...")
        s.close()
        break
      if isinstance(e, KeyboardInterrupt):
        print("\nKeyboard interrupt. Server is shutting down...")
        s.close()
        break
      else:
        raise


    
if __name__ == '__main__':
  argparse = argparse.ArgumentParser(description='Socket communication script.')
  argparse.add_argument('--ip', type=str, default='localhost', help='IP address to connect to')
  argparse.add_argument('--port', type=int, default=1234, help='Port to connect to')
  args = argparse.parse_args()

  main(args.ip, args.port)
