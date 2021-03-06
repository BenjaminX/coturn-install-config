set -ex
# SET THE FOLLOWING VARIABLES
USERNAME=[dockerhubusername]
IMAGE=coturn

# ensure we're up to date
git pull

# bump version
docker run --rm -v "$PWD":/app treeder/bump patch
version=`cat VERSION`
echo "version: $version"

# run build
./build_image.sh

# tag it
git add -A
git commit -m "version $version"
git tag -a "coturn_$version" -m "version coturn $version"
git push
git push --tags
docker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$version

# push it
docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$version
