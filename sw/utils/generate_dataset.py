import argparse
import os
import random

#
# Generate a binary dataset file with random bytes for gesture sensor
#

# Constants
DATASET_FILE = "dataset.bin"
BYTES_PER_SAMPLE = 2400

def main():
    parser = argparse.ArgumentParser(description="Generate gesture sensor dataset.")
    parser.add_argument("num_samples", type=int, help="Number of samples to generate")
    args = parser.parse_args()

    total_bytes = BYTES_PER_SAMPLE * args.num_samples
    # Generate random bytes
    data = bytearray(random.getrandbits(8) for _ in range(total_bytes))
    with open(DATASET_FILE, "wb") as f:
        f.write(data)
    print(f"Generated {args.num_samples} samples ({total_bytes} bytes) in {DATASET_FILE}.")

if __name__ == "__main__":
    main()
