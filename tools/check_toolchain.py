#!/usr/bin/env python3
"""Report reproducible tool discovery without silently skipping required tools."""

from __future__ import annotations

import shutil
import subprocess
from dataclasses import dataclass


@dataclass(frozen=True)
class Tool:
    command: str
    version_args: tuple[str, ...]
    required_now: bool


TOOLS = (
    Tool("python3", ("--version",), True),
    Tool("verilator", ("--version",), True),
    Tool("make", ("--version",), True),
    Tool("iverilog", ("-V",), False),
    Tool("yosys", ("-V",), False),
    Tool("sby", ("--version",), False),
    Tool("boolector", ("--version",), False),
    Tool("z3", ("--version",), False),
    Tool("arm-none-eabi-gcc", ("--version",), False),
    Tool("qemu-system-arm", ("--version",), False),
)


def first_version_line(tool: Tool) -> str:
    result = subprocess.run(
        (tool.command, *tool.version_args),
        check=False,
        capture_output=True,
        text=True,
    )
    output = result.stdout or result.stderr
    return output.splitlines()[0] if output.splitlines() else f"exit {result.returncode}"


def main() -> int:
    missing_required = False
    for tool in TOOLS:
        path = shutil.which(tool.command)
        role = "required" if tool.required_now else "optional"
        if path is None:
            print(f"{tool.command:22} MISSING ({role})")
            missing_required |= tool.required_now
        else:
            print(f"{tool.command:22} {first_version_line(tool)}")
    return 1 if missing_required else 0


if __name__ == "__main__":
    raise SystemExit(main())
