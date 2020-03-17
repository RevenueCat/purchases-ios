#!/bin/bash

# release a version
# usage:
# release_version.sh -c x.y.z -n a.b.c, where c = current version and n = next release
# example: release_version.sh -c 3.0.2 -n 3.1.0

while getopts ":c:n:" opt; do
  case $opt in
    c) CURRENT_VERSION="$OPTARG"
    ;;
    n) NEXT_VERSION="$OPTARG-SNAPSHOT"
    ;;
    \?) echo "Invalid option -$OPTARG. Usage: release_version.sh -c <current> -n <next>" >&2
    ;;
  esac
done

printf "current version is $CURRENT_VERSION"
printf "next version is $NEXT_VERSION"

echo "Creating a tag and pushing"
git tag -a $CURRENT_VERSION -m "Version $CURRENT_VERSION"
git push --tags

CARTHAGE_BUILDS_PATH=Carthage/Build
CARTHAGE_IOS_PATH=$CARTHAGE_BUILDS_PATH/iOS
CARTHAGE_MAC_PATH=$CARTHAGE_BUILDS_PATH/Mac
CARTHAGE_UPLOADS_PATH=CarthageUploads

cd ..

echo "Releasing version $CURRENT_VERSION"

echo "Creating RVM gemset (if needed) and activating..."
rvm gemset use --create purchases-ios

echo "Installing dependencies if needed..."
bundle install

echo "Pushing release to Cocoapods..."
pod trunk push Purchases.podspec

echo "Preparing Carthage release"
echo "building..."
carthage build --archive

echo "creating uploads folder if needed"
mkdir $CARTHAGE_UPLOADS_PATH

FRAMEWORK_NAME=Purchases.framework

mv $FRAMEWORK_NAME.zip $CARTHAGE_UPLOADS_PATH

fastlane ios github_release version:$CURRENT_VERSION

echo "Preparing next version"

BRANCH_NAME=bump/$NEXT_VERSION
echo "Creating branch $BRANCH_NAME"
git checkout -b $BRANCH_NAME

echo "bumping next version"
fastlane bump version:$NEXT_VERSION

echo "committing and pushing"
git commit -am "Preparing for next version"
git push origin $BRANCH_NAME
