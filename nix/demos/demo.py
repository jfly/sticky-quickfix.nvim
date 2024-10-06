#!/usr/bin/env python

from contextlib import contextmanager
from pathlib import Path
import argparse
import tempfile
import pexpect
import random
import sys
import os

# https://stackoverflow.com/a/12982370
ESC = "\x1b"
CSI = ESC + "["
KEY_UP = CSI + "A"


def expect_prompt(child):
    child.expect("\\$ ")


def random_human_delay_seconds() -> float:
    lower_millis = 50
    upper_millis = 100
    return random.randint(lower_millis, upper_millis) / 1000


def send(child: pexpect.spawn, cmd):
    for char in cmd:
        if char == "\r":
            # Wait a moment before sending "Enter".
            child.expect(pexpect.TIMEOUT, timeout=1)

        child.send(char)

        child.expect(pexpect.TIMEOUT, timeout=random_human_delay_seconds())

    child.expect(pexpect.TIMEOUT, timeout=1)


@contextmanager
def in_dir(d: Path):
    og_dir = Path.cwd()
    try:
        os.chdir(d)
        yield
    finally:
        os.chdir(og_dir)


@contextmanager
def tempdir():
    with tempfile.TemporaryDirectory() as temp:
        yield Path(temp)


def record(cast_file: Path, enable_plugin: bool):
    with (
        tempdir() as temp,
        in_dir(temp),
    ):
        child = pexpect.spawn(
            "asciinema",
            args=[
                "rec",
                "--overwrite",
                str(cast_file),
                "--command",
                'PS1="$ " bash --norc',
            ],
            dimensions=(20, 80),
        )
        # Needed for escape sequences to to work. See `send` for details.
        child.delaybeforesend = None
        child.logfile_read = sys.stdout.buffer
        expect_prompt(child)

        editme = temp / "hgttg.py"
        editme.write_text("\n".join(["""print(f"don't panic")"""] * 80))

        # Open the file
        send(child, f"nvim {editme.name}\r")

        if enable_plugin:
            send(child, ':lua require("sticky-quickfix").setup()\r')
        else:
            send(child, ':lua require("sticky-quickfix").stop()\r')

        # Show diagnostics quickfix list.
        send(child, ":lua vim.di\t.setqf\t()\r")

        # Select a diagonostic.
        quickfix_index = 11
        send(child, "j" * quickfix_index + "\r")

        # Fix it.
        send(child, "x")

        # Refresh the diagnostics quickfix list.
        send(child, [":", KEY_UP, "\r"])

        # Print out a message explaining what just happened.
        if enable_plugin:
            send(
                child,
                f"A  # See how the quickfix list has entry {quickfix_index} highlighted?"
                + ESC,
            )
        else:
            send(
                child,
                "A  # See how the quickfix list has the very first entry highlighted?"
                + ESC,
            )

        # Exit Vim.
        send(child, ":wqa\r")

        # Wait for Vim to exit.
        expect_prompt(child)

        # Exit shell.
        child.sendline("exit")

        # Wait for the shell to exit.
        child.expect(pexpect.EOF)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--plugin", action=argparse.BooleanOptionalAction, required=True
    )
    parser.add_argument("filename", help="filename to save the recording to", nargs="?")
    args = parser.parse_args()

    cast_file = Path.cwd() / args.filename if args.filename else Path("/dev/null")
    record(cast_file, enable_plugin=args.plugin)


if __name__ == "__main__":
    main()
