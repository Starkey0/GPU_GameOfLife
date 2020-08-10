#include "kernel.h"

__global__ void addKernel(int *c, const int *a, const int *b)
{
    int i = threadIdx.x;
    c[i] = a[i] + b[i];
}

__global__ void evolveKernel(unsigned int cells[MAX_GRID_X*MAX_GRID_Y], unsigned int newcells[MAX_GRID_X*MAX_GRID_Y])
{
    unsigned int tid = blockDim.x * blockIdx.x + threadIdx.x;
    unsigned int x,y;

    y = tid / MAX_GRID_X;
    x = tid - y* MAX_GRID_X;
    //printf("%d, %d, %d \n", tid, x, y);
    //newcells[x + y * MAX_GRID_X] = cells[x + y * MAX_GRID_X];


    if (x >= MAX_GRID_X || y >= MAX_GRID_Y)return;
    int n = 0;
    for (unsigned int y1 = y - 1; y1 <= y + 1; y1++)
        for (unsigned int x1 = x - 1; x1 <= x + 1; x1++)
            //if (!cells[(x1 + MAX_GRID_X) % MAX_GRID_X][(y1 + MAX_GRID_Y) % MAX_GRID_Y])
                //n++;
            if (!cells[(((x1 + MAX_GRID_X) % MAX_GRID_X) + ((y1 + MAX_GRID_Y) % MAX_GRID_Y) * MAX_GRID_X)])
                n++;

    if (!cells[x + y * MAX_GRID_X]) n--;
    newcells[x + y * MAX_GRID_X] = (n == 3 || (n == 2 && !cells[x + y * MAX_GRID_X])) > 0 ? 0 : 255;

    
}


// Helper function for using CUDA to add vectors in parallel.
extern "C" cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size)
{
    int *dev_a = 0;
    int *dev_b = 0;
    int *dev_c = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    // Launch a kernel on the GPU with one thread for each element.
    addKernel<<<1, size>>>(dev_c, dev_a, dev_b);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_b);
    
    return cudaStatus;
}

extern "C" cudaError_t evolveWithCuda(unsigned int h_cells[MAX_GRID_X*MAX_GRID_Y])
{
    cudaError_t cudaStatus;
    unsigned int *dA, *dB;
    size_t pitch;
    
    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    //cudaMallocPitch(&dA, &pitch, sizeof(unsigned int) * MAX_GRID_X, MAX_GRID_Y);
    cudaMalloc(&dA, sizeof(unsigned int) * MAX_GRID_X * MAX_GRID_Y);
    cudaMalloc(&dB, sizeof(unsigned int) * MAX_GRID_X * MAX_GRID_Y);

    cudaMemcpy(dA, h_cells, sizeof(unsigned int) * MAX_GRID_X * MAX_GRID_Y, cudaMemcpyHostToDevice);

    int threadsperblock = TPB;
    int blockspergrid = MAX_GRID_X * MAX_GRID_Y / threadsperblock;

    // Launch a kernel on the GPU with one thread for each element.
    evolveKernel<<<blockspergrid, threadsperblock >>>(dA, dB);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "evolveKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }

    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    cudaMemcpy(h_cells, dB, sizeof(unsigned int) * MAX_GRID_X * MAX_GRID_Y, cudaMemcpyDeviceToHost);

    cudaFree(dA);
    cudaFree(dB);

Error:

    return cudaStatus;
}
