import serial
import glob
import os
import threading
import signal
import sys

SERIAL_BAUDRATE = 144000
DEVICE_PATTERN = "/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_BG01066Q-if00-port0"

# Find the port dynamically
device_paths = glob.glob(DEVICE_PATTERN)
if not device_paths:
    raise Exception("Device not found. Please check the connection.")
else:
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
print(f"[UART ADAPTER] Serial connection opened on port {SERIAL_PORT}. Waiting for data... (Ctrl+C to exit)")

stop_event = threading.Event()

def read_from_serial():
    while not stop_event.is_set():
        try:
            incoming_message = ser.read_until(b'\n').decode('ascii')
            print(incoming_message, end='')
        except Exception:
            break

def write_to_serial():
    while not stop_event.is_set():
        try:
            user_input = input()
            ser.write(user_input.encode('ascii') + b'\r\n')
        except Exception:
            break

def shutdown(signum, frame):
    print("\n[UART ADAPTER] SIGINT received, shutting down...")
    stop_event.set()
    try:
        ser.close()
    except:
        pass
    sys.exit(0)

# Register signal handler
signal.signal(signal.SIGINT, shutdown)

read_thread = threading.Thread(target=read_from_serial, daemon=True)
write_thread = threading.Thread(target=write_to_serial, daemon=True)

read_thread.start()
write_thread.start()

# Keep main thread alive while others run
read_thread.join()
write_thread.join()
