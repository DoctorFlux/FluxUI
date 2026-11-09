"""Check publication metadata. Does not alter addon code or commit attribution."""
import argparse
import re
import subprocess
import sys

NAME = "DoctorFlux"
EMAIL = "100806234+DoctorFlux@users.noreply.github.com"


def identity(name, email):
    if (name, email) != (NAME, EMAIL):
        raise ValueError("Publication author and committer must be " + NAME + " <" + EMAIL + ">")


def message(text):
    if re.search(r"^\s*Co-authored-by\s*:", text, re.IGNORECASE | re.MULTILINE):
        raise ValueError("Publication commits must not contain co-author trailers")


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def pending():
    for variable in ("GIT_AUTHOR_IDENT", "GIT_COMMITTER_IDENT"):
        value = git("var", variable).strip()
        parsed = re.fullmatch(r"(.+) <([^>]+)> \d+ [+-]\d{4}", value)
        if not parsed:
            raise ValueError("Cannot verify pending " + variable)
        identity(*parsed.groups())


def revision(ref):
    commits = git("rev-list", ref, "--").splitlines()
    if not commits:
        raise ValueError("No publication commits to verify")
    for commit in commits:
        fields = git("show", "-s", "--format=%an%x00%ae%x00%cn%x00%ce%x00%B", commit, "--").split("\0", 4)
        if len(fields) != 5:
            raise ValueError("Cannot read publication commit " + commit)
        identity(fields[0], fields[1])
        identity(fields[2], fields[3])
        message(fields[4])
    return len(commits)


def pre_push(stream):
    count = 0
    for line in stream:
        fields = line.split()
        if len(fields) != 4:
            raise ValueError("Cannot verify push reference")
        _, local_sha, remote_ref, _ = fields
        if remote_ref != "refs/heads/main":
            raise ValueError("Only main may be published; old branches/tags must stay in recovery storage")
        if not re.fullmatch(r"[0-9a-fA-F]{40}|[0-9a-fA-F]{64}", local_sha):
            raise ValueError("Cannot verify push commit")
        if set(local_sha) == {"0"}:
            raise ValueError("Deleting the published main branch is not permitted by this hook")
        count += revision(local_sha)
    if not count:
        raise ValueError("No main publication reference to verify")
    return count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    operation = parser.add_mutually_exclusive_group(required=True)
    operation.add_argument("--pending", action="store_true")
    operation.add_argument("--message", metavar="PATH")
    operation.add_argument("--revision", metavar="REF")
    operation.add_argument("--pre-push", action="store_true")
    args = parser.parse_args()
    try:
        if args.pending:
            pending()
        elif args.message:
            from pathlib import Path
            message(Path(args.message).read_text(encoding="utf-8-sig"))
        elif args.revision:
            print("Publication identity: PASS (" + str(revision(args.revision)) + " commits)")
        else:
            print("Publication identity: PASS (" + str(pre_push(sys.stdin)) + " commits)")
    except (ValueError, OSError, UnicodeError, subprocess.CalledProcessError) as error:
        print("Publication identity: BLOCKED: " + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
