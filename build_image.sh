set -ex
# SET THE FOLLOWING VARIABLES
USERNAME=benjaminx
IMAGE=coturn
docker build -t $USERNAME/$IMAGE:latest .