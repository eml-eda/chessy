# This script is used to emulate the Chessy packet receive/send functions from Messy
#  It uses GDB in MI mode to interact with the target system
#
# Author: Lorenzo Ruotolo

FILE_REQ_ADDR = "/home/zcu102/git/chessy/req_addr.messy"
FILE_REQ_DATA = "/home/zcu102/git/chessy/req_data.messy"
CHESSY_TEST_BIN = "/home/zcu102/git/chessy/sw/cheshire/sw/tests/semihost_helloworld.spm.elf"

from pygdbmi.gdbcontroller import GdbController
import sys
import time

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

#
# Test
#

def test_chessy(gdbmi : GdbController):
    # Connect to target
    print_gdb_response(gdbmi.write('-target-select extended-remote localhost:3333'))
    # Load the binary
    print_gdb_response(gdbmi.write('-file-exec-and-symbols ' + CHESSY_TEST_BIN))
    print_gdb_response(gdbmi.write('-target-download'))
    # Break at trap_vector
    print_gdb_response(gdbmi.write('-break-insert trap_vector'))
    # Run the program
    print_gdb_response(gdbmi.write('-exec-continue'))
    
    # Stop the program
    #print_gdb_response(gdbmi.write('-exec-interrupt'))
    time.sleep(2)
    
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
