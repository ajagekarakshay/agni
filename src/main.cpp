#include <glaze/glaze.hpp>
#include <glaze/net/http_client.hpp>

#include <iostream>
#include <string>
#include <string_view>
#include <unordered_map>

struct Todo {
    int userId{};
    int id{};
    std::string title{};
    bool completed{};
};

int main(int argc, char** argv) {
    const std::string_view url = argc > 1
        ? std::string_view{argv[1]}
        : std::string_view{"https://jsonplaceholder.typicode.com/todos/1"};

    glz::http_client client;

#ifdef GLZ_ENABLE_SSL
    if (url.starts_with("https://")) {
        const auto trust_store = client.configure_system_ca_certificates();
        if (!trust_store) {
            std::cerr << "could not configure HTTPS trust store: "
                      << trust_store.error().message() << '\n';
            return 1;
        }
    }
#else
    if (url.starts_with("https://")) {
        std::cerr << "this build has HTTPS disabled; use an http:// URL or rebuild without -Dhttps=false\n";
        return 1;
    }
#endif

    const std::unordered_map<std::string, std::string> headers{
        {"Accept", "application/json"},
        {"User-Agent", "zig-glaze-example/0.2"},
    };
    const auto response = client.get(url, headers);

    if (!response) {
        std::cerr << "HTTP request failed: " << response.error().message() << '\n';
        return 1;
    }
    if (response->status_code < 200 || response->status_code >= 300) {
        std::cerr << "server returned HTTP " << response->status_code << '\n';
        return 1;
    }

    Todo todo{};
    const auto parse_error = glz::read_json(todo, response->response_body);
    if (parse_error) {
        std::cerr << "invalid JSON response:\n"
                  << glz::format_error(parse_error, response->response_body) << '\n';
        return 1;
    }

    std::cout << "HTTP " << response->status_code << '\n'
              << "todo #" << todo.id << " for user " << todo.userId << '\n'
              << "title: " << todo.title << '\n'
              << "completed: " << std::boolalpha << todo.completed << '\n';

    const auto normalized_json = glz::write_json(todo);
    if (!normalized_json) {
        std::cerr << "could not serialize the parsed object\n";
        return 1;
    }
    std::cout << "serialized again: " << *normalized_json << '\n';
}
