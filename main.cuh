#include <cstdint>

typedef int_fast64_t i64;

typedef enum {
	inpop, addop, mulop,
	divop, modop, eqlop,
} opcode_t;

typedef enum {
	wreg, xreg, yreg, zreg
} reg_t;

typedef enum {
	reg, num
} regnum_t;

typedef struct {
	opcode_t opcode;
	reg_t reg1;
	union {
		reg_t reg2;
		i64 num2;
	};
	regnum_t regnum;
} inst_t;