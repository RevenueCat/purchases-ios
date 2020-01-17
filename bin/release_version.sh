#!/bin/bash

# release a version
# usage: 
# release_version.sh -c x.y.z -n a.b.c, where c = current version and n = next release

while getopts ":c:n:" opt; do
  case $opt in
    c) CURRENT_VERSION="$OPTARG"
    ;;
    n) NEXT_VERSION="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG. Usage: release_version.sh -c <current> -n <next>" >&2
    ;;
  esac
done

printf "current version is $CURRENT_VERSION"
printf "next version is $NEXT_VERSION"

CURRENT_VERSION=$1
NEXT_VERSION=$2-SNAPSHOT

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

COCOAPODS_RESULT=$

if [ $COCOAPODS_RESULT == 0 ]; then
  echo "Successfully pushed v$CURRENT_VERSION to Cocoapods!"
else
  echo "Error pushing to Cocoapods, aborting"
  exit $COCOAPODS_RESULT
fi

echo "Preparing Carthage release"
echo "building..."
carthage build --no-skip-current

echo "creating uploads folder if needed"
mkdir $CARTHAGE_UPLOADS_PATH

echo "zipping carthage files"

FRAMEWORK_NAME=Purchases.framework
zip -r $CARTHAGE_UPLOADS_PATH/$FRAMEWORK_NAME.zip $CARTHAGE_IOS_PATH/$FRAMEWORK_NAME

IOS_DSYM_NAME=$FRAMEWORK_NAME.dSYM
zip -r $CARTHAGE_UPLOADS_PATH/$IOS_DSYM_NAME.zip $CARTHAGE_IOS_PATH/$IOS_DSYM_NAME

FRAMEWORK_NAME=Purchases.framework
zip -r $CARTHAGE_UPLOADS_PATH/$FRAMEWORK_NAME.mac.zip $CARTHAGE_MAC_PATH/$FRAMEWORK_NAME

IOS_DSYM_NAME=$FRAMEWORK_NAME.dSYM
zip -r $CARTHAGE_UPLOADS_PATH/$IOS_DSYM_NAME.mac.zip $CARTHAGE_MAC_PATH/$IOS_DSYM_NAME

echo "zipping source code"
git archive --output $CARTHAGE_UPLOADS_PATH/source.zip $CURRENT_VERSION
git archive --output $CARTHAGE_UPLOADS_PATH/source.tar.gz --format tar $CURRENT_VERSION

echo "files zipped and stored in path: $CARTHAGE_UPLOADS_PATH."
echo "Don't forget to create a release in GitHub and upload them!"

echo "Preparing next version"

BRANCH_NAME=bump/$NEXT_VERSION
echo "Creating branch $BRANCH_NAME"
git checkout -b $BRANCH_NAME

echo "bumping next version"
fastlane bump version:$NEXT_VERSION

echo "committing and pushing"
git commit -am "Preparing for next version"
git push origin $BRANCH_NAME

echo "All set! Don't forget to create the new release in GitHub and upload the files in $CARTHAGE_UPLOADS_PATH!"
