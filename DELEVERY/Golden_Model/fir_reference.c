#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>

#define NUM_SAMPLES 100
#define NUM_TAPS 73
#define MAX_16BIT 32767
#define MIN_16BIT -32768

int main() {
    int16_t inputs[NUM_SAMPLES];
    int16_t coeffs[NUM_TAPS];
    int16_t delay_line[NUM_TAPS] = {0}; 
    int16_t outputs[NUM_SAMPLES];

    srand((unsigned int)time(NULL));

    FILE *fin = fopen("input_stimulus.txt", "w");
    if (!fin) {
        printf("Error: Could not create input_stimulus.txt\n");
        return -1;
    }
    
    for (int i = 0; i < NUM_SAMPLES; i++) {
        inputs[i] = (rand() % 8192) - 4096;
        fprintf(fin, "%04X\n", (uint16_t)inputs[i]);
    }
    fclose(fin);

    FILE *fc = fopen("coeffs_q15.txt", "r");
    if (!fc) {
        printf("Error: Could not open coeffs_q15.txt. Ensure the file is in the same directory.\n");
        return -1;
    }
    
    for (int i = 0; i < NUM_TAPS; i++) {
        int temp_val;
        fscanf(fc, "%d", &temp_val);
        coeffs[i] = (int16_t)temp_val;
    }
    fclose(fc);

    FILE *fout = fopen("expected_outputs.txt", "w");
    if (!fout) {
        printf("Error: Could not create expected_outputs.txt\n");
        return -1;
    }

    for (int i = 0; i < NUM_SAMPLES; i++) {
        for (int j = NUM_TAPS - 1; j > 0; j--) {
            delay_line[j] = delay_line[j - 1];
        }
        delay_line[0] = inputs[i];
        int32_t accumulator = 0;
        for (int j = 0; j < NUM_TAPS; j++) {
            accumulator += (int32_t)delay_line[j] * (int32_t)coeffs[j];
        }
        int32_t shifted_result = accumulator >> 12;
        if (shifted_result > MAX_16BIT) {
            shifted_result = MAX_16BIT;
        } else if (shifted_result < MIN_16BIT) {
            shifted_result = MIN_16BIT;
        }

        outputs[i] = (int16_t)shifted_result;
        fprintf(fout, "%04X\n", (uint16_t)outputs[i]);
    }
    fclose(fout);

    printf("Golden Reference Model executed successfully.\n");
    printf("Check 'input_stimulus.txt' and 'expected_outputs.txt' for the generated data.\n");

    return 0;
}
