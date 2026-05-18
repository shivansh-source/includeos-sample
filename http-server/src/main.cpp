#include <arpa/inet.h>
#include <cerrno>
#include <cstring>
#include <iostream>
#include <netinet/in.h>
#include <string>
#include <sys/socket.h>
#include <unistd.h>

namespace {
constexpr int kPort = 8080;
constexpr int kBacklog = 16;
constexpr std::size_t kBufferSize = 1024;

const char kResponse[] =
    "HTTP/1.1 200 OK\r\n"
    "Content-Type: text/plain\r\n"
    "Content-Length: 13\r\n"
    "Connection: close\r\n"
    "\r\n"
    "Hello, world!";

bool send_all(int fd, const char* data, std::size_t length) {
    std::size_t sent = 0;
    while (sent < length) {
        const ssize_t result = send(fd, data + sent, length - sent, 0);
        if (result < 0) {
            if (errno == EINTR) {
                continue;
            }
            perror("send");
            return false;
        }
        sent += static_cast<std::size_t>(result);
    }
    return true;
}
} // namespace

int main() {
    const int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket failed");
        return 1;
    }

    int opt = 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
        perror("setsockopt");
        close(server_fd);
        return 1;
    }

    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(kPort);

    if (bind(server_fd, reinterpret_cast<sockaddr*>(&address), sizeof(address)) < 0) {
        perror("bind failed");
        close(server_fd);
        return 1;
    }

    if (listen(server_fd, kBacklog) < 0) {
        perror("listen");
        close(server_fd);
        return 1;
    }

    std::cout << "HTTP Server listening on 0.0.0.0:" << kPort << "..." << std::endl;

    while (true) {
        sockaddr_in client_address{};
        socklen_t client_address_len = sizeof(client_address);
        const int client_fd = accept(
            server_fd,
            reinterpret_cast<sockaddr*>(&client_address),
            &client_address_len);
        if (client_fd < 0) {
            if (errno == EINTR) {
                continue;
            }
            perror("accept");
            close(server_fd);
            return 1;
        }

        char buffer[kBufferSize] = {0};
        const ssize_t bytes_read = read(client_fd, buffer, sizeof(buffer) - 1);
        if (bytes_read < 0) {
            perror("read");
            close(client_fd);
            continue;
        }

        char client_ip[INET_ADDRSTRLEN] = {0};
        inet_ntop(AF_INET, &client_address.sin_addr, client_ip, sizeof(client_ip));
        std::cout << "Received request from " << client_ip << ":"
                  << ntohs(client_address.sin_port) << std::endl;

        send_all(client_fd, kResponse, sizeof(kResponse) - 1);
        close(client_fd);
    }
}
