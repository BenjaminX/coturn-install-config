set -ex
# SET THE FOLLOWING VARIABLES
USERNAME=[dockerhubusername]
IMAGE=coturn
docker build -t $USERNAME/$IMAGE:latest .