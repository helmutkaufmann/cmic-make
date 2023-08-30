#/bin/bash

# Install libraries and compilers
brew install --quiet opencv libheif fftw llvm libomp

# Set environment variables
# Note that LLVM-capable C and C++ compilers are needed, hence the settings for CC and CXX
export CC=/opt/homebrew/opt/llvm/bin/clang
export CXX=/opt/homebrew/opt/llvm/bin/clang++
export C_INCLUDE_PATH=/opt/homebrew/include:/opt/homebrew/opt/libomp/include
export CPLUS_INCLUDE_PATH=/opt/homebrew/include:/opt/homebrew/opt/libomp/include
export LD_LIBRARY_PATH=/opt/homebrew/lib:/opt/homebrew/opt/libomp/lib
export PKG_CONFIG_PATH=/opt/homebrew/lib/pkgconfig
export CONFIG+=openmp

# Get or update required repositories
git clone https://github.com/GreycLab/gmic 2> /dev/null || git -C gmic pull
git clone https://github.com/GreycLab/CImg 2> /dev/null || git -C CImg pull 
git clone https://github.com/GreycLab/gmic-community 2> /dev/null || git -C gmic-community pull
git clone https://github.com/helmutkaufmann/gmic-qt 2> /dev/null || git -C gmic-qt pull

# 
# Build gmic
# 

# First, determine current gmic version
cd gmic/src
RELEASE0=`grep "#define gmic_version" gmic.h | tail -c 5`
RELEASE1=`echo $RELEASE0 | head -c 1`
RELEASE2=`echo $RELEASE0 | head -c 2 | tail -c 1`
RELEASE3=`echo $RELEASE0 | head -c 3 | tail -c 1`

# Second, set and display version identifier
VERSION=$RELEASE1.$RELEASE2.$RELEASE3
DATE=$(date "+%Y-%m-%d-%H:%M:%S")
echo "Buildinbg version ${VERSION} as of ${DATE}"

# Third, build gmic
make clean 
make -B OPENCV_CFLAGS="\$(shell pkg-config opencv4 --cflags)" OPENCV_LIBS="\$(shell pkg-config opencv4 --libs)" EXTRA_CFLAGS="-fopenmp -I/opt/homebrew/include -I/opt/homebrew/include/opencv4 -I/opt/local/include -march=native -flto -Wno-unused-parameter -Wno-c11-extensions -Wno-deprecated-declarations -Wno-c++17-extensions -Wno-variadic-macros -Dcimg_use_opencv \$(OPENCV_CFLAGS) -Dcimg_use_heif" EXTRA_LIBS="\$(OPENCV_LIBS) -L/opt/homebrew/lib -lheif" cli
cd ../..

# 
# Build gmic-qt
# 

make -C gmic/src CImg.h gmic_stdlib_community.h
cd gmic-qt
qmake LFLAGS=-L/opt/homebrew/lib CONFIG+=${config} HOST=none GMIC_PATH=../gmic/src QMAKE_CC=/opt/homebrew/opt/llvm/bin/clang QMAKE_CXX=/opt/homebrew/opt/llvm/bin/clang++ QMAKE_LINK="/opt/homebrew/opt/llvm/bin/clang++ -L/opt/homebrew/lib" "QMAKE_CFLAGS=-I/opt/homebrew/include" "QMAKE_CXXFLAGS=-I/opt/homebrew/include" QMAKE_EXPORT_ARCH_ARGS="''" QTPLUGIN.platforms=- 
make -B "SUBLIBS=-lX11"
cd ..

# 
# Copy executables
# 
sudo cp gmic/src/gmic gmic-qt/gmic_qt.app/Contents/MacOS/gmic_qt /usr/local/bin/
echo "Build complete and copied to /usr/local/bin - Enjoy!"
