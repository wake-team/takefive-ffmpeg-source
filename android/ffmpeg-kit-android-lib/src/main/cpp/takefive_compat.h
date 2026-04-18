#pragma once
/* Force-include standard headers that fftools sources expect but may miss
   due to FFmpeg config.h side effects on Android NDK builds. */
#include <time.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
