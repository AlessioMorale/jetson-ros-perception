ARG sourceimage
FROM $sourceimage
COPY ./buildfiles/* /ros_catkin_ws/
RUN /ros_catkin_ws/build_workspace