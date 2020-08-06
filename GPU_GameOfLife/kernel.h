#ifndef KERNEL
#define KERNEL

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

#define MAX_GRID_X 100
#define MAX_GRID_Y 100

#define SCREENWIDTH 800
#define SCREENHEIGHT 800

#define CELL_SIZE 4
#define CELL_POW 3

#define for_x for (int x = 0; x < MAX_GRID_X; x++)
#define for_y for (int y = 0; y < MAX_GRID_Y; y++)
#define for_xy for_x for_y

#define TPB 256
#define PDIM 100
#define DIV 2


#endif






