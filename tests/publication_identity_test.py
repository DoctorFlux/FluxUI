"""Publication policy regression checks; no game, Git index or repository writes."""
import importlib.util
import io
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("publication_identity", Path(__file__).resolve().parents[1]/"tools/check_publication_identity.py")
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


class PublicationPolicy(unittest.TestCase):
    def test_publication_identity(self):
        policy.identity(policy.NAME, policy.EMAIL)
        for name, email in [("Codex", "codex@openai.com"), ("codexCodex", policy.EMAIL),
                            (policy.NAME, "codex@openai.com"), ("github-actions[bot]", policy.EMAIL),
                            (policy.NAME, ""), ("", policy.EMAIL)]:
            with self.subTest(name=name, email=email), self.assertRaises(ValueError):
                policy.identity(name, email)

    def test_pending_environment_override(self):
        valid = policy.NAME+" <"+policy.EMAIL+"> 1794200000 +0100\n"
        invalid = "Codex <codex@openai.com> 1794200000 +0100\n"
        with patch.object(policy, "git", return_value=valid):
            policy.pending()
        for replies in ([invalid, valid], [valid, invalid], ["malformed"]):
            with self.subTest(replies=replies), patch.object(policy, "git", side_effect=replies), self.assertRaises(ValueError):
                policy.pending()

    def test_coauthor_trailers(self):
        policy.message("Fix focus input\n\nKeep native menu behavior.\n")
        for trailer in ("Co-authored-by: Codex <codex@openai.com>",
                        "co-AUTHORED-by: codexCodex <example@example.com>",
                        "  Co-authored-by : Another Author <another@example.com>"):
            with self.subTest(trailer=trailer), self.assertRaises(ValueError):
                policy.message("Change\n\n"+trailer+"\n")

    def test_reachable_ancestor_is_checked(self):
        good = "\0".join([policy.NAME, policy.EMAIL, policy.NAME, policy.EMAIL, "Snapshot\n"])
        bad = "\0".join(["Codex", "codex@openai.com", policy.NAME, policy.EMAIL, "Old commit\n"])
        with patch.object(policy, "git", side_effect=["a\nb\n", good, bad]), self.assertRaises(ValueError):
            policy.revision("HEAD")
        with patch.object(policy, "git", side_effect=["a\n", good]):
            self.assertEqual(policy.revision("HEAD"), 1)

    def test_push_references(self):
        commit = "a"*40
        with patch.object(policy, "revision", return_value=1) as check:
            self.assertEqual(policy.pre_push(io.StringIO("refs/heads/main "+commit+" refs/heads/main "+"0"*40+"\n")), 1)
            check.assert_called_once_with(commit)
        for entry in ("", "malformed\n", "main "+commit+" refs/tags/old "+commit+"\n",
                      "main "+"0"*40+" refs/heads/main "+commit+"\n", "main nope refs/heads/main "+commit+"\n"):
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                policy.pre_push(io.StringIO(entry))


if __name__ == "__main__":
    unittest.main()
