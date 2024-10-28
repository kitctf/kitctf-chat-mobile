#!/usr/bin/env bash
set -eu

if [ -n "$RELEASE_KEYSTORE" ]; then
    echo "Writing keystore"
    echo "$RELEASE_KEYSTORE" | base64 -d > kitctf_chat.keystore
fi

if [ -d mattermost-mobile ]; then
    rm -rf mattermost-mobile
fi

git clone https://github.com/mattermost/mattermost-mobile

pushd mattermost-mobile || exit 1

# Setup config for git am
git config --global user.email "mattermost@kitctf.de"
git config --global user.name "KITCTF Mattermost patcher"

if [ -n "$TARGET_REV" ]; then
    git checkout "$TARGET_REV"
fi

for patch in ../*.patch; do
    echo "Applying $patch"
    git am "$patch"
done

npm install

pushd fastlane || exit 2
bundle install
popd || exit 2

{
    echo "MATTERMOST_RELEASE_STORE_FILE=$PWD/../kitctf_chat.keystore";
    echo "MATTERMOST_RELEASE_KEY_ALIAS=kitctf_chat"  >> android/gradle.properties;
    echo "MATTERMOST_RELEASE_PASSWORD=${RELEASE_PASSWORD}";
} >> android/gradle.properties


cd fastlane
NODE_ENV=production bundle exec fastlane android build --env android.release

popd || exit
