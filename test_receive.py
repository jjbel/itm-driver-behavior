import socket

listen_ip="127.0.0.1"
listen_port=5013
buffer_size=2 ** 15

recv_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
recv_socket.bind((listen_ip, listen_port))

try:
    while True:
        data, addr = recv_socket.recvfrom(buffer_size)
        print(data, addr)
except KeyboardInterrupt:
    pass

recv_socket.close()
