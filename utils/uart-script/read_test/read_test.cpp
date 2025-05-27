#include <cstdio>
#include <string.h>

// UART
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <fstream>
#include <sys/ioctl.h>

#include <iostream>
#include <json.hpp>

#define UART_BAUD_RATE 144000
#define UART_DEVICE_PATTERN "/dev/uart"

// extended termios struct for custom baud rate
struct termios2
{
    tcflag_t c_iflag; /* input mode flags */
    tcflag_t c_oflag; /* output mode flags */
    tcflag_t c_cflag; /* control mode flags */
    tcflag_t c_lflag; /* local mode flags */
    cc_t c_line;      /* line discipline */
    cc_t c_cc[NCCS];  /* control characters */
    speed_t c_ispeed; /* input speed */
    speed_t c_ospeed; /* output speed */
};

using json = nlohmann::json;

#define DEBUG_LEVEL 2
#define DEBUG_LEVEL_HIGH 1

json read_uart_data(int fd)
{
    int num_read, counter_read, string_length;
    unsigned char rd_len_buffer[4];
    char *rd_json_buffer;
    json data;

    // Read how many characters the json will be long
    string_length = 0;
    num_read = read(fd, rd_len_buffer, 4);

    for (int i = 0; i < num_read; i++)
        string_length = string_length | (rd_len_buffer[i] << (8 * i));

#if DEBUG_LEVEL >= DEBUG_LEVEL_HIGH
    std::cout << "Incoming packet of length: " << string_length << std::endl;
#endif

    // Use the number to allocate memory required to store the json string
    num_read = 0;
    counter_read = 0;
    rd_json_buffer = (char *)malloc((string_length + 1) * sizeof(char));

#if DEBUG_LEVEL >= DEBUG_LEVEL_HIGH
    std::cout << "Allocated buffer of size: " << (string_length + 1) << std::endl;
#endif

    while (counter_read < string_length)
    {
        num_read = read(fd, rd_json_buffer + counter_read, string_length - counter_read);
        counter_read += num_read;

#if DEBUG_LEVEL >= DEBUG_LEVEL_HIGH
        std::cout << "Read " << num_read << " bytes, total read: " << counter_read << " bytes" << std::endl;
#endif

        if (num_read == 0)
            break;
    }
    rd_json_buffer[counter_read] = '\0';

#if DEBUG_LEVEL >= DEBUG_LEVEL_HIGH
    std::cout << "Packet received with length: " << counter_read << std::endl;
    std::cout << "Received JSON string: " << rd_json_buffer << std::endl;
#endif

    // Parse the json
    data = json::parse(rd_json_buffer);
    free(rd_json_buffer);
    return data;
}

int main()
{
    int uart_fd;
    uart_fd = open(UART_DEVICE_PATTERN, O_RDONLY | O_NOCTTY);

    if (uart_fd < 0)
    {
        perror("Failed to open UART port");
        exit(1);
    }

#if DEBUG_LEVEL >= DEBUG_LEVEL_HIGH
    std::cout << "UART port opened successfully" << std::endl;
#endif

    // Store current UART configuration into uart_tty
    struct termios2 uart_tty;
    ioctl(uart_fd, TCGETS2, &uart_tty);
    // Set custom baud rate
    uart_tty.c_cflag &= ~CBAUD;
    uart_tty.c_cflag |= CBAUDEX;
    uart_tty.c_ispeed = UART_BAUD_RATE;
    uart_tty.c_ospeed = UART_BAUD_RATE;
    // Use custom termios struct to update UART configuration
    ioctl(uart_fd, TCSETS2, &uart_tty);

#if DEBUG_LEVEL >= DEBUG_LEVEL_HIGH
    std::cout << "UART configuration set with baud rate: " << UART_BAUD_RATE << std::endl;
#endif

    json result = read_uart_data(uart_fd);
    std::cout << "Parsed JSON data: " << result.dump(4) << std::endl;

    close(uart_fd);

#if DEBUG_LEVEL >= DEBUG_LEVEL_HIGH
    std::cout << "UART port closed" << std::endl;
#endif

    return 0;
}
