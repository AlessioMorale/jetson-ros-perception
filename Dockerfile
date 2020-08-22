ARG sourceimage
FROM $sourceimage

RUN mkdir -p /ros_perception_ws/src
COPY ./buildfiles/* /ros_perception_ws/

# build the workspace
WORKDIR /ros_perception_ws
RUN for i in *.rosinstall; do echo - $i && vcs import src < `echo $i`; done
RUN sudo apt-get install ros-melodic-pcl-ros libflann-dev -y --no-install-recommends && \
    apt-get clean autoclean -y && \
    cd /ros_perception_ws/src/vision_opencv/cv_bridge && \
    git apply /ros_perception_ws/cv_bridge.patch

RUN /bin/bash -c "source /docker-entrypoint.sh && rosdep install --from-paths src --ignore-src --rosdistro melodic -y --skip-keys='python3-opencv opencv libopencv-dev' && apt-get clean autoclean -y"

RUN /bin/bash -c "source /docker-entrypoint.sh && catkin config -DCMAKE_BUILD_TYPE=Release -DPYTHON_EXECUTABLE=/usr/bin/python3 -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m -DPYTHON_LIBRARY=/usr/lib/aarch64-linux-gnu/libpython3.6m.so && catkin build --no-status --interleave -v"

# Set up entrypoint
RUN echo "source /ros_perception_ws/devel/setup.bash" >> /source_workspaces
