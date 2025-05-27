import serial
import glob
import os
import threading

SERIAL_BAUDRATE = 144000
DEVICE_PATTERN = "/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_BG01066Q-if00-port0"

# Find the port dynamically
device_paths = glob.glob(DEVICE_PATTERN)
if not device_paths:
    raise Exception("Device not found. Please check the connection.")
else:
    # Resolve the symlink to get the actual device path
    SERIAL_PORT = os.path.realpath(device_paths[0])

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
print(f"[SCRIPT] Serial connection opened on port {SERIAL_PORT}. Waiting for data...")

def read_from_serial():
    while True:
        incoming_message = ser.read_until(b'\n').decode('ascii')
        print(incoming_message, end='')

def write_to_serial():
    while True:
        user_input = input()
        ser.write(user_input.encode('ascii') + b'\r\n')

try:
    read_thread = threading.Thread(target=read_from_serial)
    write_thread = threading.Thread(target=write_to_serial)

    read_thread.start()
    write_thread.start()

    read_thread.join()
    write_thread.join()

except KeyboardInterrupt:
    print("\nExiting...")

finally:
    if ser.is_open:
        ser.close()
    print("[SCRIPT] Serial connection closed.")
