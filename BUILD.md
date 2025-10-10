# Build Instructions

## Prerequisites

### All Platforms
- CMake >= 3.15
- C/C++ compiler (GCC, Clang, or MSVC)
- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0

### Android
- Android NDK r21 or later
- Android SDK Build-Tools 30.0.0 or later

### iOS/macOS
- Xcode 14.0 or later
- CocoaPods

### Linux
- Build essentials: `sudo apt-get install build-essential cmake`
- pthread library

### Windows
- Visual Studio 2019 or later with C++ tools
- CMake

## Building the Native Libraries

### HevSocks5

```bash
cd flutter_vpn_hev5socks
mkdir build
cd build
cmake ..
cmake --build .
cmake --install . --prefix ../dist
```

### Tun2Socks

```bash
cd flutter_vpn_tun2socks
mkdir build
cd build
cmake ..
cmake --build .
cmake --install . --prefix ../dist
```

### SingBox

```bash
cd flutter_vpn_singbox
mkdir build
cd build
cmake ..
cmake --build .
cmake --install . --prefix ../dist
```

### VPN Engine (Main)

```bash
cd flutter_vpn_engine
mkdir build
cd build
cmake ..
cmake --build .
cmake --install . --prefix ../dist
```

## Building for Android

### Set up NDK

```bash
export ANDROID_NDK=/path/to/android/ndk
```

### Build for Android

```bash
cd flutter_vpn_engine
mkdir build-android
cd build-android

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release

cmake --build .
```

### Build for multiple ABIs

```bash
for ABI in armeabi-v7a arm64-v8a x86 x86_64; do
  mkdir -p build-android-$ABI
  cd build-android-$ABI
  
  cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$ABI \
    -DANDROID_PLATFORM=android-21 \
    -DCMAKE_BUILD_TYPE=Release
  
  cmake --build .
  cd ..
done
```

## Building for iOS/macOS

### iOS (Device)

```bash
cd flutter_vpn_engine
mkdir build-ios
cd build-ios

cmake .. \
  -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
  -DCMAKE_BUILD_TYPE=Release

cmake --build . --config Release
```

### iOS (Simulator)

```bash
cmake .. \
  -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
  -DCMAKE_BUILD_TYPE=Release

cmake --build . --config Release
```

### macOS

```bash
cd flutter_vpn_engine
mkdir build-macos
cd build-macos

cmake .. \
  -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 \
  -DCMAKE_BUILD_TYPE=Release

cmake --build .
```

## Building for Linux

```bash
cd flutter_vpn_engine
mkdir build-linux
cd build-linux

cmake .. \
  -DCMAKE_BUILD_TYPE=Release

cmake --build .
```

## Building for Windows

### Using Visual Studio

```bash
cd flutter_vpn_engine
mkdir build-windows
cd build-windows

cmake .. -G "Visual Studio 16 2019" -A x64
cmake --build . --config Release
```

### Using MinGW

```bash
cmake .. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

## Building the Flutter Package

### Get dependencies

```bash
cd flutter_vpn_engine
flutter pub get
```

### Generate FFI bindings (optional)

```bash
dart run ffigen --config ffigen.yaml
```

### Run tests

```bash
flutter test
```

### Build example app

```bash
cd example
flutter pub get
flutter run
```

## Cross-compilation

### Android from Linux/macOS

```bash
./scripts/build_android.sh
```

### iOS from macOS

```bash
./scripts/build_ios.sh
```

## Build Scripts

We provide helper scripts in `scripts/` directory:

- `build_all.sh` - Build for all platforms
- `build_android.sh` - Build for Android (all ABIs)
- `build_ios.sh` - Build for iOS
- `build_macos.sh` - Build for macOS
- `build_linux.sh` - Build for Linux
- `build_windows.sh` - Build for Windows

### Usage

```bash
cd flutter_vpn_engine/scripts
chmod +x *.sh
./build_all.sh
```

## Troubleshooting

### CMake can't find dependencies

Make sure all submodules are updated:
```bash
git submodule update --init --recursive
```

### Android NDK not found

Set the ANDROID_NDK environment variable:
```bash
export ANDROID_NDK=/path/to/android/ndk
```

### iOS build fails

Make sure Xcode command line tools are installed:
```bash
xcode-select --install
```

### Library not loading on runtime

Check library paths and make sure they're in the correct location:
- Android: `app/src/main/jniLibs/<ABI>/`
- iOS: Embedded in framework
- Linux: `/usr/local/lib/` or set `LD_LIBRARY_PATH`
- Windows: Same directory as executable or in `PATH`

## Development Build (with debug symbols)

```bash
cmake .. -DCMAKE_BUILD_TYPE=Debug
cmake --build .
```

## Release Build (optimized)

```bash
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
cmake --build .
```

## Clean Build

```bash
rm -rf build
mkdir build
cd build
cmake ..
cmake --build .
```

## Testing Native Code

```bash
cd flutter_vpn_engine
mkdir build
cd build
cmake .. -DBUILD_TESTS=ON
cmake --build .
ctest
```

## Continuous Integration

See `.github/workflows/` for CI/CD pipeline configurations.


