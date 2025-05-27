# import serial

# # Open the serial connection
# ser = serial.Serial(
#     port="/dev/ttyUSB1",
#     baudrate=144000,
#     bytesize=serial.EIGHTBITS,
#     parity=serial.PARITY_NONE,
#     stopbits=serial.STOPBITS_ONE,
#     xonxoff=False,
#     rtscts=False,
#     dsrdtr=False,
# )

# print("Serial connection opened. Listening for data...")

# try:
#     while True:
#         # if ser.in_waiting > 0:
#         # Read one byte from the serial port
#         byte = ser.read(1)
#         # # Convert the byte to its hexadecimal, binary, and ASCII representations
#         hex_value = byte.hex()
#         bin_value = bin(int.from_bytes(byte, byteorder="big"))[2:].zfill(8)
#         ascii_value = byte.decode("ascii", errors="replace")
#         print("byte: ", byte)

#         # Print the values
#         # print(f"Hex: {hex_value} | Binary: {bin_value} | ASCII: {ascii_value}")

# except KeyboardInterrupt:
#     # Exit the loop on a keyboard interrupt (Ctrl+C)
#     print("Exiting...")

# finally:
#     # Close the serial connection
#     ser.close()
#     print("Serial connection closed.")

import serial
import glob
import os

# Find the port dynamically
DEVICE_PATTERN = "/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_BG01066Q-if00-port0"
device_paths = glob.glob(DEVICE_PATTERN)

if not device_paths:
    raise Exception("Device not found. Please check the connection.")
else:
    # Resolve the symlink to get the actual device path
    SERIAL_PORT = os.path.realpath(device_paths[0])

SERIAL_BAUDRATE = 144000 # Make sure this matches __BOOT_BAUDRATE in your C program

# Open the serial connection
ser = serial.Serial(
    port=SERIAL_PORT,
    baudrate=SERIAL_BAUDRATE,
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    xonxoff=False,
    rtscts=False,
    dsrdtr=False,
)

print(f"Serial connection opened on port {SERIAL_PORT}. Waiting for data...")

try:
    # Read and print the initial message
    initial_message = ser.read_until(b'\n').decode('ascii')
    print(initial_message, end='')

    # Read and print the prompt
    prompt = ser.read_until(b'\n').decode('ascii')
    print(prompt, end='')

    # Get user input and send it to the device
    user_input = input()
    ser.write(user_input.encode('ascii') + b'\r\n')

    # Read and print the echoed input
    echoed_input = ser.read_until(b'\n').decode('ascii')
    print(echoed_input, end='')

    # Read and print the final message
    final_message = ser.read_until(b'\n').decode('ascii')
    print(final_message, end='')

except KeyboardInterrupt:
    print("\nExiting...")

finally:
    ser.close()
    print("Serial connection closed.")
