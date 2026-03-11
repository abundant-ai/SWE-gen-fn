#!/bin/bash
# Reverse the bug.patch to get back to the fixed state
patch -R -p1 < /tmp/bug.patch
