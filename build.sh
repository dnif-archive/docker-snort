set -ex
# SET THE FOLLOWING VARIABLES
# docker hub username
USERNAME=dnif
# image name
IMAGE=snort
docker build -t $USERNAME/$IMAGE:latest .
