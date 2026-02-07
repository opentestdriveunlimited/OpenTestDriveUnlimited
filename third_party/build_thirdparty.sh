#!/bin/bash
echo "Building Cityhash..."
pushd cityhash
./configure
popd

echo "Building libbinkdec..."
pushd libbinkdec
working_dir=$(pwd)
cmake . -DBUILD_SHARED=0 -B build -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="${working_dir}/lib" -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY="${working_dir}/lib" -DCMAKE_BUILD_TYPE=Release
cd build
cmake --build .
popd

echo "Building zlib..."
pushd zlib
working_dir=$(pwd)
cmake -S . -DZLIB_BUILD_SHARED=0 -DZLIB_BUILD_TESTING=0 -DZLIB_BUILD_MINIZIP=0 -B build -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY="${working_dir}/lib" -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="{working_dir}/lib" -DCMAKE_BUILD_TYPE=Release
cd build
cmake --build .
popd

if [ $? -ne 0 ]; then
    echo "ThirdParty deps failed to build!"
    exit 1
fi

exit 0
