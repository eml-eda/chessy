CXX = g++
CXXFLAGS = -Wall -std=c++11

# Include paths
INCLUDES = -I.

# Source files
SRCS = read_test.cpp

# Output executable
TARGET = read_test

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET) $(SRCS)

clean:
	rm -f $(TARGET)
