#!/bin/sh

if [ ! -d ../docs/ ]; then mkdir ../docs ; fi
rm -rf ../docs/*
cp -r ../akka-docs-zh/target/paradox/site/main/* ../docs/
