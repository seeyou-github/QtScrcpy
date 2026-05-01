import sys
import os
import subprocess


def git_output(args):
    try:
        return subprocess.check_output(args, stderr=subprocess.DEVNULL, text=True).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""

if __name__ == '__main__':
    version_file = os.path.abspath(os.path.join(os.path.dirname(__file__), "../QtScrcpy/appversion"))
    fallback_version = "0.0.0"
    if os.path.exists(version_file):
        with open(version_file, "r", encoding="utf-8") as file:
            fallback_version = file.read().strip() or fallback_version

    version = fallback_version
    tag = git_output(['git', 'describe', '--tags', '--abbrev=0'])
    if tag:
        version = tag[1:] if tag.startswith('v') else tag

    with open(version_file, 'w', encoding='utf-8') as file:
        file.write(version)

    sys.exit(0)
