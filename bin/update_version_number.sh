# updates the version number
# usage: update_version_number.sh x.y.z

VERSION=$1

echo "Creating RVM gemset (if needed) and activating..."
rvm gemset use --create purchases-ios

echo "Installing dependencies if needed..."
bundle install


