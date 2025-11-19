#!/usr/bin/env python3
"""Run a command behind a pseudo-terminal with optional scripted input."""

import os
import select
import sys


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: run_with_pty.py COMMAND [ARGS...]", file=sys.stderr)
        return 2

    input_data = os.environ.get("WIZARDRY_PTY_INPUT", "").encode()
    written = 0

    pid, fd = os.forkpty()
    if pid == 0:
        os.execvp(sys.argv[1], sys.argv[1:])

    try:
        while True:
            read_fds = [fd]
            write_fds = [fd] if written < len(input_data) else []
            ready_read, ready_write, _ = select.select(read_fds, write_fds, [], 0.1)

            if ready_write:
                chunk = input_data[written:]
                if chunk:
                    written += os.write(fd, chunk)

            if ready_read:
                try:
                    output = os.read(fd, 1024)
                except OSError:
                    output = b""
                if not output:
                    break
                sys.stdout.buffer.write(output)
                sys.stdout.buffer.flush()
    finally:
        os.close(fd)

    _, status = os.waitpid(pid, 0)
    if os.WIFEXITED(status):
        return os.WEXITSTATUS(status)
    if os.WIFSIGNALED(status):
        return 128 + os.WTERMSIG(status)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
