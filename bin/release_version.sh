#!/bin/bash

# release a version
# usage: 
# release_version.sh -c x.y.z -n a.b.c, where c = current version and n = next release

while getopts ":c:n:" opt; do
  case $opt in
    c) arg_1="$OPTARG"
    ;;
    n) p_out="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG. Usage: release_version.sh -c <current> -n <next>" >&2
    ;;
  esac
done

printf "Argument p_out is %s\n" "$p_out"
printf "Argument arg_1 is %s\n" "$arg_1"

VERSION=$1

echo "Creating a tag and pushing"
git tag -a $VERSION -m "Version $VERSION"
git push --tags

CARTHAGE_BUILDS_PATH=Carthage/Build
CARTHAGE_IOS_PATH=$CARTHAGE_BUILDS_PATH/iOS
CARTHAGE_MAC_PATH=$CARTHAGE_BUILDS_PATH/Mac
CARTHAGE_UPLOADS_PATH=CarthageUploads

cd ..

echo "Releasing version $VERSION"

echo "Creating RVM gemset (if needed) and activating..."
# rvm gemset use --create purchases-ios

echo "Installing dependencies if needed..."
# bundle install

echo "Pushing release to Cocoapods..."
# pod trunk push Purchases.podspec

# COCOAPODS_RESULT=$
COCOAPODS_RESULT=0

if [ $COCOAPODS_RESULT == 0 ]; then
	echo "Successfully pushed v$VERSION to Cocoapods!"
else
	echo "Error pushing to Cocoapods, aborting"
	exit $COCOAPODS_RESULT
fi

echo "Preparing Carthage release"
echo "building..."
# carthage build --no-skip-current

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
git archive --output $CARTHAGE_UPLOADS_PATH/source.zip $VERSION
git archive --output $CARTHAGE_UPLOADS_PATH/source.tar.gz --format tar $VERSION

echo "files zipped and stored in path: $CARTHAGE_UPLOADS_PATH."
echo "Don't forget to create a release in GitHub and upload them!"

