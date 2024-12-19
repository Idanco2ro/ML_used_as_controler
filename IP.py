import socket

# Configurare parametri
HOST = '127.0.0.1'  # Adresa locală (localhost)
PORT = 55000  # Portul folosit

# Inițializare socket
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    client_socket.connect((HOST, PORT))  # Conectare la server (Simulink)
    print(f"Conectat la {HOST}:{PORT}")

    # Trimite un mesaj test (sau implementează comunicarea reală aici)
    mesaj = "Salut, Simulink!".encode('utf-8')
    client_socket.sendall(mesaj)

    # Primiți răspuns de la Simulink (dacă este cazul)
    data = client_socket.recv(1024)
    print(f"Răspuns de la Simulink: {data.decode('utf-8')}")
finally:
    client_socket.close()
    print("Conexiune închisă.")
