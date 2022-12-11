FROM ubuntu:22.04

# # Since ubuntu 19.10 isn't LTS, use LTS sources for the packages we need.
# RUN sed -i "s/archive/old-releases/" /etc/apt/sources.list \
#     && sed -i "/security/d" /etc/apt/sources.list \
#     && apt-get update

# We need Nvidia Drivers
RUN apt-get -y update
RUN apt install -y --no-install-recommends apt-utils software-properties-common gpg-agent
# RUN add-apt-repository -y ppa:graphics-drivers/ppa
RUN add-apt-repository universe
RUN apt-get -y update

# Set nvidia-driver installation to not ask for keyboard configeration
RUN apt-get install -y keyboard-configuration
ENV DEBIAN_FRONTEND noninteractive

# Needed Libraries for Dandere2x
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update
RUN apt-get install python3.8 -y

RUN apt install -y --no-install-recommends ffmpeg nvidia-driver-440 libvulkan1 libgtk2.0-dev pkg-config

# Needed Library for Building Dandere2x (this will be removed later)
RUN apt-get install -y cmake
RUN apt-get install -y git-core
RUN apt-get install -y build-essential
RUN apt-get install -y libgl1-mesa-glx
RUN apt-get install -y ffmpeg
RUN apt-get install -y wget
RUN apt-get install -y zip
RUN apt-get install -y curl

# Move Dandere2x's files to /dandere2x/
RUN mkdir /dandere2x/
RUN git clone --recurse-submodules --progress https://github.com/aka-katto/dandere2x.git /dandere2x/dandere2x

# Begin the building process
RUN cd /dandere2x/dandere2x/src/ && bash /dandere2x/dandere2x/src/unix_setup.sh

RUN wget https://github.com/nihui/waifu2x-ncnn-vulkan/releases/download/20200606/waifu2x-ncnn-vulkan-20200606-linux.zip
RUN unzip waifu2x-ncnn-vulkan-20200606-linux.zip
RUN mv waifu2x-ncnn-vulkan-20200606-linux /dandere2x/dandere2x/src/externals/waifu2x-ncnn-vulkan
RUN rm waifu2x-ncnn-vulkan-20200606-linux.zip

# Install Python Dependencies (note pyyaml has to be manually installed due to ubuntu:19.10 python3.8 restriction)
# Ubuntu 19.10 will by default use python3.75 rather than the needed 3.8, so we have to manually get pip and refer to python + python as 3.8

RUN apt-get install python3-distutils python3-apt python3-pip -y
RUN pip3 install -r /dandere2x/dandere2x/src/requirements.txt

RUN apt -y install ocl-icd-opencl-dev
RUN apt -y install libopencv-dev libopencv-imgcodecs-dev libopencv-imgproc-dev libopencv-core-dev
RUN apt -y install nvidia-cuda-toolkit
WORKDIR /dandere2x
RUN git clone "https://github.com/DeadSix27/waifu2x-converter-cpp"
WORKDIR /dandere2x/waifu2x-converter-cpp
RUN mkdir out
WORKDIR /dandere2x/waifu2x-converter-cpp/out
RUN cmake ..
RUN make -j4

WORKDIR /dandere2x/dandere2x/src/
ENTRYPOINT ["python3.8", "/dandere2x/dandere2x/src/main.py"]

ENV NVIDIA_DRIVER_CAPABILITIES all
ENV DEBIAN_FRONTEND teletype
