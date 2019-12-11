cmake_minimum_required(VERSION 3.12)

project(SEALExamples VERSION 3.4.4 LANGUAGES CXX)

add_executable(key_generator key_generator.cpp)
add_executable(weights_encryptor weights_encryptor.cpp)
add_executable(calculator calculator.cpp)
add_executable(sumcheck sumcheck.cpp)

# Import Microsoft SEAL
find_package(SEAL 3.4.4 EXACT REQUIRED)

# Link Microsoft SEAL
target_link_libraries(key_generator SEAL::seal)
target_link_libraries(weights_encryptor SEAL::seal)
target_link_libraries(calculator SEAL::seal)
target_link_libraries(sumcheck SEAL::seal)