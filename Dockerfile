ARG sourceimage
FROM $sourceimage AS BASE
# install pcl and overwrite with the compiled version to satisfy all dependencies
SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    time apt-get install \
    libflann-dev \
    libpcl-dev \
    -y --no-install-recommends && \
    apt-get clean autoclean -y && \
    rm -rf /usr/include/pcl-1.8/ && \
    rm -rf /usr/lib/aarch64-linux-gnu/cmake/pcl && \
    rm /usr/lib/aarch64-linux-gnu/libpcl_* && \
    rm /usr/lib/aarch64-linux-gnu/pkgconfig/pcl_* && \
    rm -rf /usr/share/doc/libpcl-*
WORKDIR /root/
COPY /buildfiles/* /root/
RUN source /root/setup_ccache

RUN --mount=type=secret,id=secrets,dst=/secrets \
    --mount=type=cache,target=/root/ccache \
    source /secrets && \
    source /root/setup_ccache && \
    download_cache && \
    git clone --depth 1 -b pcl-1.8.1 https://github.com/PointCloudLibrary/pcl.git pcl && \
    mkdir -p pcl/build && \
    cd pcl/build && \
    cmake \
    -DCUDA_ARCH_BIN=5.3 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_GPU=ON \
    -DWITH_QT=OFF \
    -DWITH_CUDA=ON \
    -DWITH_LIBUSB=OFF \
    -DWITH_OPENNI2=OFF \
    -DBUILD_apps=OFF \
    -DBUILD_examples=OFF\
    .. && \
    time make -j6 && \
    upload_cache && \
    time make install && \
    rm -rf /root/pcl

RUN mkdir -p /ros_perception_ws/src
COPY ./buildfiles/* /ros_perception_ws/

# build the workspace
WORKDIR /ros_perception_ws
RUN for i in *.rosinstall; do echo - $i && vcs import src < `echo $i`; done
RUN cd /ros_perception_ws/src/vision_opencv/cv_bridge && \
    git apply /ros_perception_ws/cv_bridge.patch

RUN apt-get update && \
    source /docker-entrypoint.sh && \
    time rosdep install --from-paths src --ignore-src --rosdistro melodic -y --skip-keys='python3-opencv opencv libopencv-dev' && \
    apt-get clean autoclean -y

RUN --mount=type=secret,id=secrets,dst=/secrets \
    --mount=type=cache,target=/root/ccache \
    source /secrets && \
    source /root/setup_ccache && \
    source /docker-entrypoint.sh && \
    catkin config \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m \
    -DPYTHON_LIBRARY=/usr/lib/aarch64-linux-gnu/libpython3.6m.so && \
    time catkin build --no-status --interleave && \
    upload_cache
# Set up entrypoint

RUN echo "source /ros_perception_ws/devel/setup.bash" >> /init_workspaces
