#!/usr/bin/env bash

VALUE=${1?Error: no number given}

git tag $VALUE
git push origin $VALUE

xcodebuild build -scheme JZCalendarWeekView -destination "generic/platform=iOS Simulator"