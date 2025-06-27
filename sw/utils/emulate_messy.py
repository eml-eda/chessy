# This script is used to emulate the Chessy packet receive/send functions from Messy
#  It uses GDB in MI mode to interact with the target system
#
# Author: Lorenzo Ruotolo

FILE_REQ_ADDR = "/home/zcu102/git/chessy/req_addr.messy"
FILE_REQ_DATA = "/home/zcu102/git/chessy/req_data.messy"
CHESSY_TEST_BIN = "/home/zcu102/git/chessy/sw/cheshire/sw/tests/fake_sensor.spm.elf"

from pygdbmi.gdbcontroller import GdbController
import sys
import time

DEBUG = False

#
# Formatting utilities
#

# ANSI colors for console output
class Color:
    RESET = "\033[0m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    CYAN = "\033[36m"
    MAGENTA = "\033[35m"
    GRAY = "\033[90m"

def color_print(text, color):
    print(f"{color}{text}{Color.RESET}")

def print_gdb_response(response):
    if not DEBUG:
        color_print("Sent GDB Command @ " + time.strftime("%Y-%m-%d %H:%M:%S"), Color.GRAY)
    else:
        color_print("GDB Response @ " + time.strftime("%Y-%m-%d %H:%M:%S"), Color.MAGENTA)    
        for resp in response:
            resp_type = resp.get('type')
            payload = resp.get('payload')
            
            if payload and 'msg' in payload:
                content = payload['msg']
            elif payload:
                content = payload
            else:
                content = str(resp)
                
            # Filter out unneeded banner messages
            if resp_type == 'console' and ('GNU gdb' in content or 'Copyright' in content):
                continue

            if resp_type == 'result':
                if resp.get('message') == 'done':
                    color_print(f"[DONE] {content}", Color.GREEN)
                elif resp.get('message') == 'error':
                    color_print(f"[ERROR] {content}", Color.RED)
                else:
                    color_print(f"[RESULT] {resp.get('message')}", Color.CYAN)
            elif resp_type == 'console':
                color_print(f"[CONSOLE] {content.strip()}", Color.YELLOW)
            elif resp_type == 'log':
                color_print(f"[LOG] {content.strip()}", Color.GRAY)
            elif resp_type == 'target':
                color_print(f"[TARGET] {content.strip()}", Color.CYAN)
            elif resp_type == 'notify':
                #color_print(f"[NOTIFY] {content}", Color.GRAY)
                continue
            else:
                print(resp)

def parse_value_from_response(response):
    for resp in response:
        if resp.get('type') == 'result' and resp.get('message') == 'done':
            if 'value' in resp.get('payload', {}):
                return resp['payload']['value']

    return None

#
# Test
#

def test_chessy(gdbmi : GdbController):
    # Connect to target
    print_gdb_response(gdbmi.write('-target-select extended-remote localhost:3333'))
    # Load the binary
    print_gdb_response(gdbmi.write('-file-exec-and-symbols ' + CHESSY_TEST_BIN))
    print_gdb_response(gdbmi.write('-target-download'))

    # Wait for the break 1
    print_gdb_response(gdbmi.write('-exec-continue', timeout_sec=20))
    sensor_addr = parse_value_from_response(gdbmi.write('-data-evaluate-expression sensor_address'))
    sensor_data = int(parse_value_from_response(gdbmi.write('-data-evaluate-expression sensor_data')))
    new_data = sensor_data + 1
    print(f"Sensor address: {sensor_addr}, Sensor data: {sensor_data}, New data: {new_data}")
    
    print_gdb_response(gdbmi.write('set $pc=$pc+2'))  # Skip the ebreak
    print_gdb_response(gdbmi.write('-exec-continue'))

    # Wait for the break 2
    print_gdb_response(gdbmi.write('-exec-continue', timeout_sec=20))
    new_sensor_addr = parse_value_from_response(gdbmi.write('-data-evaluate-expression sensor_address'))
    if new_sensor_addr == sensor_addr:
        print_gdb_response(gdbmi.write('set sensor_data=' + str(new_data)))
        print(f"Sensor address: {new_sensor_addr}, Sensor data updated to: {new_data}")
    print_gdb_response(gdbmi.write('set $pc=$pc+2'))  # Skip the ebreak
    print_gdb_response(gdbmi.write('-exec-continue'))
    
    # Wait for finish
    print_gdb_response(gdbmi.write('-exec-continue', timeout_sec=20, raise_error_on_timeout=False))
    
    return

#
# Main
#

def main():
    gdbmi = GdbController(command=['riscv64-unknown-elf-gdb', '--nx', '--interpreter=mi'])

    # Disable pagination and verbose messages inside GDB
    gdbmi.write('-gdb-set pagination off')
    gdbmi.write('-gdb-set verbose off')
    gdbmi.write('-gdb-set confirm off')

    try:
        test_chessy(gdbmi)

    except KeyboardInterrupt:
        print("\nExiting...")
    finally:
        gdbmi.exit()

if __name__ == "__main__":
    main()
