#!/bin/bash

set -ex
export TRAVIS_BUILD_DIR=$(pwd)
export TRAVIS_BRANCH=$DRONE_BRANCH
export TRAVIS_OS_NAME=${DRONE_JOB_OS_NAME:-linux}
export VCS_COMMIT_ID=$DRONE_COMMIT
export GIT_COMMIT=$DRONE_COMMIT
export DRONE_CURRENT_BUILD_DIR=$(pwd)
export PATH=~/.local/bin:$PATH

echo '==================================> BEFORE_INSTALL'

. .drone/before-install.sh

echo '==================================> INSTALL'

GIT_FETCH_JOBS=8
BOOST_BRANCH=develop
if [ "$TRAVIS_BRANCH" = "master" ]; then BOOST_BRANCH=master; fi
cd ..
git clone -b $BOOST_BRANCH --depth 1 https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule init tools/build
git submodule init tools/boostdep
git submodule init tools/boost_install
git submodule init libs/headers
git submodule init libs/config
git submodule update --jobs $GIT_FETCH_JOBS
cp -r $TRAVIS_BUILD_DIR/* libs/filesystem
python tools/boostdep/depinst/depinst.py --git_args "--jobs $GIT_FETCH_JOBS" filesystem
./bootstrap.sh
./b2 headers

echo '==================================> BEFORE_SCRIPT'

. $DRONE_CURRENT_BUILD_DIR/.drone/before-script.sh

echo '==================================> COMPILE'

BUILD_JOBS=`(nproc || sysctl -n hw.ncpu) 2> /dev/null`
mkdir __build_static__ && cd __build_static__
cmake ../libs/filesystem/test/test_cmake
cmake --build . --target boost_filesystem_cmake_self_test -j $BUILD_JOBS
cd ..
mkdir __build_shared__ && cd __build_shared__
cmake -DBUILD_SHARED_LIBS=On ../libs/filesystem/test/test_cmake
cmake --build . --target boost_filesystem_cmake_self_test -j $BUILD_JOBS

echo '==================================> AFTER_SUCCESS'

. $DRONE_CURRENT_BUILD_DIR/.drone/after-success.sh
