/* CIS565 CUDA Checker: A simple CUDA hello-world style program for
   Patrick Cozzi's CIS565: GPU Computing at the University of Pennsylvania
   Written by Yining Karl Li, Liam Boone, and Harmony Li.
   Copyright (c) 2014 University of Pennsylvania */

#include <stdio.h>
#include <iostream>
#include "kernel.h"

void CheckCUDAError(const char *msg)
{
    cudaError_t err = cudaGetLastError();
    if (cudaSuccess != err) {
        fprintf(stderr, "Cuda error: %s: %s.\n", msg, cudaGetErrorString( err));
        exit(EXIT_FAILURE);
    }
}

// Kernel that writes the image to the OpenGL PBO directly.
__global__ void CreateVersionVisualization(uchar4* PBOpos, int width, int height, int major,
        int minor)
{
    int x = (blockIdx.x * blockDim.x) + threadIdx.x;
    int y = (blockIdx.y * blockDim.y) + threadIdx.y;
    int index = x + (y * width);

    if (x <= width && y <= height) {
        // Each thread writes one pixel location in the texture (textel)
        PBOpos[index].w = 0;
        PBOpos[index].x = 0;
        PBOpos[index].y = 0;
        PBOpos[index].z = 0;

        int ver = y < height / 2 ? major : minor;
        if (ver == 0) {
            PBOpos[index].x = 255;
        } else if (ver == 1) {
            PBOpos[index].y = 255;
        } else if (ver == 2) {
            PBOpos[index].z = 255;
        } else if (ver == 3) {
            PBOpos[index].x = 255;
            PBOpos[index].y = 255;
        } else if (ver == 5) {
            PBOpos[index].z = 255;
            PBOpos[index].y = 255;
        }
    }
}

// Wrapper for the __global__ call that sets up the kernel calls
void CudaKernel(uchar4* PBOpos, int width, int height, int major, int minor)
{
    // set up crucial magic
    int tileSize = 16;
    dim3 threadsPerBlock(tileSize, tileSize);
    dim3 fullBlocksPerGrid((int)ceil(width / float(tileSize)), (int)ceil(height / float(tileSize)));

    //kernel launches
    CreateVersionVisualization <<< fullBlocksPerGrid, threadsPerBlock>>>(PBOpos, width, height,
            major, minor);
    // make certain the kernel has completed
    cudaThreadSynchronize();

    CheckCUDAError("Kernel failed!");
}
