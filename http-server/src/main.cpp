
#include <service>
#include <net/http/server.hpp>
#include <net/interfaces>

std::unique_ptr<http::Server> server_;

void Service::start(const std::string&) {}

void Service::ready() {
  auto& inet = net::Interfaces::get(0);
  inet.network_config(
    {10, 0, 0, 46},
    {255, 255, 255, 0},
    {10, 0, 0, 1},
    {8, 8, 8, 8}
  );

  server_ = std::make_unique<http::Server>(inet.tcp());

  server_->on_request([](auto, auto writer) {
    writer->header().set_field(http::header::Content_Type, "text/plain");
    writer->write("Hello, world!");
  });

  server_->listen(8080);
}
