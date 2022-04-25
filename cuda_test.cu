#include <stdio.h>
#include <stdlib.h>
#include <time.h>

extern "C" {
#include "acpc_server_code/game.h"
}

// For the CUDA runtime routines (prefixed with "cuda_")
#include <cuda_runtime.h>

#include <helper_cuda.h>

const uint32_t LENGTH = MAX_SUITS * MAX_RANKS;

/**
 * CUDA Kernel Device code
 *
 * Computes the vector addition of A and B into C. The 3 vectors have the same
 * number of elements numElements.
 */
__global__ void cudaTest(uint8_t *Res, int numElements) 
{
  int i = blockDim.x * blockIdx.x + threadIdx.x;

  uint8_t p2[2] = {makeCard(10, 1), makeCard(8, 1)};

  const uint16_t P1_HAND_SET_SIZE = 338; // 169 * 2 (two cards per hand)
  uint8_t p1HandSet[P1_HAND_SET_SIZE] = {
      0, 4, 0, 8, 0, 12, 0, 16, 0, 20, 0, 24, 0, 28, 0, 32, 0, 36, 0, 40, 0, 44, 0, 48, 4, 8, 4, 12, 4, 16, 4, 20, 4, 24, 4, 28, 4, 32, 4, 36, 4, 40, 4, 44, 4, 48, 8, 12, 8, 16, 8, 20, 8, 24, 8, 28, 8, 32, 8, 36, 8, 40, 8, 44, 8, 48, 12, 16, 12, 20, 12, 24, 12, 28, 12, 32, 12, 36, 12, 40, 12, 44, 12, 48, 16, 20, 16, 24, 16, 28, 16, 32, 16, 36, 16, 40, 16, 44, 16, 48, 20, 24, 20, 28, 20, 32, 20, 36, 20, 40, 20, 44, 20, 48, 24, 28, 24, 32, 24, 36, 24, 40, 24, 44, 24, 48, 28, 32, 28, 36, 28, 40, 28, 44, 28, 48, 32, 36, 32, 40, 32, 44, 32, 48, 36, 40, 36, 44, 36, 48, 40, 44, 40, 48, 44, 48, // Suited
      0, 1, 4, 5, 8, 9, 12, 13, 16, 17, 20, 21, 24, 25, 28, 29, 32, 33, 36, 37, 40, 41, 44, 45, 48, 49,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           // Pairs
      0, 5, 0, 9, 0, 13, 0, 17, 0, 21, 0, 25, 0, 29, 0, 33, 0, 37, 0, 41, 0, 45, 0, 49, 4, 9, 4, 13, 4, 17, 4, 21, 4, 25, 4, 29, 4, 33, 4, 37, 4, 41, 4, 45, 4, 49, 8, 13, 8, 17, 8, 21, 8, 25, 8, 29, 8, 33, 8, 37, 8, 41, 8, 45, 8, 49, 12, 17, 12, 21, 12, 25, 12, 29, 12, 33, 12, 37, 12, 41, 12, 45, 12, 49, 16, 21, 16, 25, 16, 29, 16, 33, 16, 37, 16, 41, 16, 45, 16, 49, 20, 25, 20, 29, 20, 33, 20, 37, 20, 41, 20, 45, 20, 49, 24, 29, 24, 33, 24, 37, 24, 41, 24, 45, 24, 49, 28, 33, 28, 37, 28, 41, 28, 45, 28, 49, 32, 37, 32, 41, 32, 45, 32, 49, 36, 41, 36, 45, 36, 49, 40, 45, 40, 49, 44, 49  // Unsuited
  };

  const uint16_t p1Idx = i * 2;

  uint8_t p1[2] = {p1HandSet[p1Idx], p1HandSet[p1Idx + 1]};

  const uint32_t DECK_SIZE = 48;
  uint8_t deck[DECK_SIZE];

  for (uint8_t c = 0, i = 0; c < LENGTH; ++c)
  {
    if (c == p1[0] || c == p1[1] || c == p2[0] || c == p2[1])
      continue;

    deck[i] = c;
    ++i;
  }

  uint32_t count = numElements / (P1_HAND_SET_SIZE / 2) * i;

  for (uint8_t f1Idx = 0; f1Idx < DECK_SIZE; ++f1Idx)
  {
    for (uint8_t f2Idx = f1Idx + 1; f2Idx < DECK_SIZE; ++f2Idx)
    {
      for (uint8_t f3Idx = f2Idx + 1; f3Idx < DECK_SIZE; ++f3Idx)
      {
        for (uint8_t tIdx = f3Idx + 1; tIdx < DECK_SIZE; ++tIdx)
        {
          for (uint8_t rIdx = tIdx + 1; rIdx < DECK_SIZE; ++rIdx)
          {
            Res[count] = count % 3;
            ++count;
          }
        }
      }
    }
  }
}

/**
 * Host main routine
 */
int main(void) {
  // Error code to check return values for CUDA calls
  cudaError_t err = cudaSuccess;

  // Print the vector length to be used, and compute its size
  int numElements = 289379376;
  size_t size = numElements * sizeof(uint8_t);
  printf("[Vector addition of %d elements]\n", numElements);

  // Allocate the host input vector A
  uint8_t *h_Res = (uint8_t *)malloc(size);

  // Verify that allocations succeeded
  if (h_Res == NULL) {
    fprintf(stderr, "Failed to allocate host vectors!\n");
    exit(EXIT_FAILURE);
  }

  // Initialize the host input vectors
  for (int i = 0; i < numElements; ++i) {
    h_Res[i] = -1;
  }

  clock_t start = clock();

  // Allocate the device input vector A
  uint8_t *d_Res = NULL;
  err = cudaMalloc((void **)&d_Res, size);

  if (err != cudaSuccess) {
    fprintf(stderr, "Failed to allocate device vector A (error code %s)!\n",
            cudaGetErrorString(err));
    exit(EXIT_FAILURE);
  }

  // Copy the host input vectors A and B in host memory to the device input
  // vectors in
  // device memory
  printf("Copy input data from the host memory to the CUDA device\n");
  err = cudaMemcpy(d_Res, h_Res, size, cudaMemcpyHostToDevice);

  if (err != cudaSuccess) {
    fprintf(stderr,
            "Failed to copy vector A from host to device (error code %s)!\n",
            cudaGetErrorString(err));
    exit(EXIT_FAILURE);
  }

  // Launch the Vector Add CUDA Kernel
  int threadsPerBlock = 256;
  int blocksPerGrid = (numElements + threadsPerBlock - 1) / threadsPerBlock;
  printf("CUDA kernel launch with %d blocks of %d threads\n", blocksPerGrid,
         threadsPerBlock);
  cudaTest<<<1, 169>>>(d_Res, numElements);
  err = cudaGetLastError();

  if (err != cudaSuccess) {
    fprintf(stderr, "Failed to launch cudaTest kernel (error code %s)!\n",
            cudaGetErrorString(err));
    exit(EXIT_FAILURE);
  }

  // Copy the device result vector in device memory to the host result vector
  // in host memory.
  printf("Copy output data from the CUDA device to the host memory\n");
  err = cudaMemcpy(h_Res, d_Res, size, cudaMemcpyDeviceToHost);

  if (err != cudaSuccess) {
    fprintf(stderr,
            "Failed to copy vector C from device to host (error code %s)!\n",
            cudaGetErrorString(err));
    exit(EXIT_FAILURE);
  }

  clock_t end = clock();
  double diff = (double)(end - start) / (double)(CLOCKS_PER_SEC);

  printf("Calc took: %0.10f\n", diff);

  // Verify that the result vector is correct
  for (int i = 0; i < numElements; ++i) {
    if (h_Res[i] == -1) {
      fprintf(stderr, "Result verification failed at element %d!\n", i);
      exit(EXIT_FAILURE);
    }
  }

  printf("Test PASSED\n");

  // Free device global memory
  err = cudaFree(d_Res);

  if (err != cudaSuccess) {
    fprintf(stderr, "Failed to free device vector A (error code %s)!\n",
            cudaGetErrorString(err));
    exit(EXIT_FAILURE);
  }

  // Free host memory
  free(h_Res);

  printf("Done\n");

  return 0;
}
