ARG CUDA="11.6.0"
ARG UBUNTU="20.04"

FROM nvidia/cuda:${CUDA}-cudnn8-devel-ubuntu${UBUNTU}

ARG PYTHON="3.8"
ARG OPENCV="4.6.0"
# Change CUDA_ARCH_BIN to the compute capability of your GPU architecture, for more information see https://developer.nvidia.com/cuda-gpus. In this case we're using Tesla T4 GPU.
ARG CUDA_ARCH_BIN="7.5" 
ARG CUDNN="ON"
ARG DEBIAN_FRONTEND=noninteractive

ENV PIP_ROOT_USER_ACTION=ignore

RUN apt update \
    && apt install -y --no-install-recommends python3 python3-pip python3-numpy python3-dev \
    && ln -sf python3 /usr/bin/python \
    && ln -sf pip3 /usr/bin/pip \
    && pip install --upgrade pip \
    && pip install wheel setuptools

# Install OpenCV and DLIB build dependencies
RUN apt update && apt install -y --no-install-recommends gcc-10 \
    g++-10 \
    build-essential \ 
    ninja-build \
    cmake \ 
    wget \
    unzip \
    pkg-config \
    yasm \ 
    git \
    checkinstall \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libavcodec-dev \ 
    libavformat-dev \
    libswscale-dev \ 
    libxvidcore-dev x264 \
    libx264-dev \
    libfaac-dev \
    libmp3lame-dev \
    libtheora-dev \ 
    libfaac-dev \
    libmp3lame-dev \
    libvorbis-dev \
    libtbb2 \
    libblas-dev \
    libeigen3-dev \
    liblapack-dev \
    libatlas-base-dev \
    libgomp1 \
    python3-dev \
    python3-numpy \ 
    software-properties-common \
    apt-utils \
    libxine2-dev \
    libv4l-dev \
    libpq-dev \
    v4l-utils

# Download and build OpenCV with CUDA support
# From: https://github.com/thecanadianroot/opencv-cuda-docker/blob/main/Dockerfile
WORKDIR /tmp
RUN wget -q https://github.com/opencv/opencv/archive/refs/tags/${OPENCV}.zip && unzip ${OPENCV}.zip && rm ${OPENCV}.zip
RUN wget -q https://github.com/opencv/opencv_contrib/archive/refs/tags/${OPENCV}.zip && unzip ${OPENCV}.zip && rm ${OPENCV}.zip
RUN mkdir opencv-${OPENCV}/build && \
    cd opencv-${OPENCV}/build && \
    cmake -GNinja -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D WITH_TBB=ON \
    -D ENABLE_FAST_MATH=1 \
    -D CUDA_FAST_MATH=1 \
    -D WITH_CUBLAS=1 \
    -D WITH_CUDA=ON \
    -D BUILD_opencv_cudacodec=OFF \
    -D WITH_V4L=ON \
    -D WITH_QT=OFF \
    -D WITH_OPENGL=ON \
    -D WITH_GSTREAMER=ON \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D OPENCV_PC_FILE_NAME=opencv.pc \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D OPENCV_EXTRA_MODULES_PATH=/tmp/opencv_contrib-${OPENCV}/modules \
    -D WITH_CUDNN=${CUDNN} \
    -D OPENCV_DNN_CUDA=${CUDNN} \
    -D BUILD_JAVA=OFF \
    -D BUILD_opencv_python2=OFF \
    -D BUILD_opencv_python3=ON \
    -D HAVE_opencv_python3=ON \
    -D CUDA_ARCH_BIN=${CUDA_ARCH_BIN} \
    -D CUDA_ARCH_PTX="" \
    -D PYTHON_DEFAULT_EXECUTABLE=/usr/bin/python \
    -D PYTHON3_EXECUTABLE=/usr/bin/python \
    -D PYTHON3_PACKAGES_PATH=/usr/local/lib/python${PYTHON}/dist-packages/ \
    -D OPENCV_PYTHON3_INSTALL_PATH=/usr/local/lib/python${PYTHON}/dist-packages/ \
    -D INSTALL_PYTHON_EXAMPLES=OFF \
    -D INSTALL_C_EXAMPLES=OFF \
    -D BUILD_EXAMPLES=OFF \
    .. && \
    ninja && \
    ninja install && \
    ldconfig

# Download and build Dlib with CUDA support
RUN git clone https://github.com/davisking/dlib.git
RUN cd dlib \
    && mkdir build \
    && cd build \
    && cmake .. -DCUDA_HOST_COMPILER=/usr/bin/gcc -DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/ -DDLIB_USE_CUDA=1 -DUSE_AVX_INSTRUCTIONS=1 -DUSE_F16C=1 \
    && cmake --build . --config Release \
    && ldconfig

RUN cd dlib && python3 setup.py install