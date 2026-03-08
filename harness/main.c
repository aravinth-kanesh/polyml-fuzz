// main.c -- AFL++ persistent-mode harness for Poly/ML (reference only, not used)
//
// NOTE: This harness is NOT used by the fuzzing campaigns. It is retained as a
// record of the initial design. The campaigns fuzz the instrumented poly binary
// directly (see campaign/launch.sh).
//
// Why this approach was abandoned:
//   This harness invokes poly via system("poly < input.sml"), which spawns poly
//   as a child process. AFL++ cannot track edge coverage inside a child process
//   launched with system(), so coverage feedback was limited to the ~12 edges in
//   this harness itself -- not the lexer or parser code we care about. Switching
//   to direct fuzzing of the poly binary gives full coverage of libpolyml/.
//
// Build with:
//   afl-clang-fast -Wall -Wextra -O2 -fsanitize=address,undefined -o harness_afl main.c
//
// This harness:
//  - runs in AFL++ persistent mode (__AFL_LOOP)
//  - reads each testcase from stdin
//  - writes it to input.sml
//  - invokes the Poly/ML binary ("poly < input.sml")
//
// Poly/ML is built with AFL++ instrumentation but without compile-time
// sanitisers (to avoid bootstrap issues). ASan/UBSan are enabled at
// runtime via AFL_USE_ASAN=1 and AFL_USE_UBSAN=1.

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/wait.h>
#include <errno.h>

static const char *INPUT_FILE = "input.sml";

// Helper: write buffer to input.sml (truncate on each iteration)
static int write_input_file(const unsigned char *buf, ssize_t len) {
    int fd = open(INPUT_FILE, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (fd < 0) {
        perror("open input.sml");
        return -1;
    }

    ssize_t off = 0;
    while (off < len) {
        ssize_t n = write(fd, buf + off, (size_t)(len - off));
        if (n < 0) {
            if (errno == EINTR) continue;
            perror("write input.sml");
            close(fd);
            return -1;
        }
        off += n;
    }

    close(fd);
    return 0;
}

// Helper: run "poly < input.sml"
static int run_poly(void) {
    int status = system("poly < input.sml");

    // system() returns -1 on failure, or a status value that encodes
    // exit code and signal. We don't need to decode it here: AFL++
    // will see crashes via the child process exit status.
    if (status == -1) {
        perror("system(poly)");
    }

    return status;
}

int main(int argc, char **argv) {

    // 64 KiB input buffer is usually enough for compiler frontends.
    static unsigned char buf[64 * 1024];

    // Persistent loop: AFL++ will feed a new testcase each iteration.
    while (__AFL_LOOP(1000)) {

        // Read one testcase from stdin (AFL feeds input via stdin).
        ssize_t len = read(STDIN_FILENO, buf, sizeof(buf));
        if (len <= 0) {
            // No more data or error -- break out of the loop.
            break;
        }

        // Write testcase to input.sml
        if (write_input_file(buf, len) != 0) {
            // If the harness itself fails, we just stop fuzzing.
            break;
        }

        // Run Poly/ML on the input file.
        (void)run_poly();

        // Poly/ML + ASan/UBSan will crash with a signal if there is
        // a serious bug. AFL++ will see that as a crash.
    }

    return 0;
}