#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "main.cuh"

#define MAX_NUM 22876792454960 // 88888888888888 in base 9

static void parse_input(const char *filename, inst_t **outarr, size_t *outlen);
__global__ void get_max_input(const inst_t *insts, size_t len, i64 *outputs);
__device__ int simulate(const inst_t *insts, size_t len, i64 num);

int main(int argc, char **argv) {
	if(argc <= 1) {
		fprintf(stderr, "error: no filename supplied\n");
		return 1;
	}

	char *filename = argv[1];

	inst_t *insts;
	size_t inst_num;
	parse_input(filename, &insts, &inst_num);

	inst_t *d_insts;
	cudaMalloc(&d_insts, inst_num * sizeof(inst_t));
	cudaMemcpy(d_insts, insts, inst_num * sizeof(inst_t), cudaMemcpyHostToDevice);

	size_t threads_per_block = 256;
	size_t num_blocks = 4096;
	size_t total_threads = threads_per_block * num_blocks;

	i64 *d_outputs;
	cudaMalloc(&d_outputs, total_threads * sizeof(i64));

	get_max_input<<<num_blocks, threads_per_block>>>(d_insts, inst_num, d_outputs);

	i64 *outputs = (i64 *) calloc(total_threads, sizeof(i64));
	cudaMemcpy(outputs, d_outputs, total_threads * sizeof(i64), cudaMemcpyDeviceToHost);

	i64 maximum = 0;
	for(size_t i = 0; i < total_threads; i++) {
		maximum = (outputs[i] > maximum) ? outputs[i] : maximum;
	}

	printf("Finished! maximum = %lld\n", maximum);

	free(outputs);
	cudaFree(d_outputs);
	cudaFree(d_insts);
	free(insts);

	return 0;
}

__global__ void get_max_input(const inst_t *insts, size_t len, i64 *outputs) {
	size_t base = blockIdx.x * blockDim.x + threadIdx.x;
	size_t stride = blockDim.x * gridDim.x;
	
	for(i64 i = MAX_NUM - base; i >= 0; i -= stride) {
		if(simulate(insts, len, i) == 0) {
			outputs[base] = i;
			return;
		}
	}
	outputs[base] = 0;
}

__device__ int simulate(const inst_t *insts, size_t len, i64 n) {
	return 1; // TODO
}

static opcode_t parse_opcode(const char *line) {
	if(strstr(line, "inp")) {
		return inpop;
	} else if(strstr(line, "add")) {
		return addop;
	} else if(strstr(line, "mul")) {
		return mulop;
	} else if(strstr(line, "div")) {
		return divop;
	} else if(strstr(line, "mod")) {
		return modop;
	} else if(strstr(line, "eql")) {
		return eqlop;
	} else {
		fprintf(stderr, "error: invalid opcode (%s)\n", line);
		exit(1);
	}
}

static reg_t parse_reg(char reg) {
	switch(reg) {
	case 'w':
		return wreg;
	case 'x':
		return xreg;
	case 'y':
		return yreg;
	case 'z':
		return zreg;
	default:
		fprintf(stderr, "error: invalid register (%c)\n", reg);
		exit(1);
	}
}

static inst_t parse_inst(const char *line) {
	inst_t inst;
	inst.opcode = parse_opcode(line);
	inst.reg1 = parse_reg(line[4]);

	if(isalpha(line[6])) {
		inst.reg2 = parse_reg(line[6]);
		inst.regnum = reg;
	} else {
		inst.num2 = atoi(&line[6]);
		inst.regnum = num;
	}

	return inst;
}

static void parse_input(const char *filename, inst_t **outarr, size_t *outlen) {
	FILE *input = fopen(filename, "r");
	*outlen = 0;
	int ch;
	while(EOF != (ch = fgetc(input))) {
		if(ch == '\n') (*outlen)++;
	}

	rewind(input);

	*outarr = (inst_t *)calloc(*outlen, sizeof(inst_t));

	char line[20];
	size_t idx = 0;
	while(NULL != fgets(line, 20, input) && idx < *outlen) {
		(*outarr)[idx] = parse_inst(line);
		idx++;
	}

	if(!feof(input)) {
		fprintf(stderr, "error: didn't read input stream to end\n");
		exit(1);
	}

	fclose(input);
}

