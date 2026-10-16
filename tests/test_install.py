"""Installer integration checks using disposable checkouts and HOME directories."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class InstallTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="agent-setup-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "source checkout"
        self.source.mkdir()
        shutil.copytree(REPO / "skills", self.source / "skills")
        shutil.copy2(REPO / "install.sh", self.source / "install.sh")
        self.home = self.root / "home"
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home))
        self.skills = sorted((self.source / "skills").glob("*/SKILL.md"))

    def install(self, piped=False, check=True):
        return subprocess.run(
            ["bash"] if piped else ["bash", str(self.source / "install.sh")],
            input=(self.source / "install.sh").read_text() if piped else None,
            text=True, capture_output=True, env=self.env, cwd=self.root, check=check,
        )

    def write(self, relative, text):
        path = self.home / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def test_shared_links_references_and_live_edits(self):
        self.install()
        self.assertEqual(len(self.skills), 21)
        for skill in self.skills:
            for app in (".agents", ".claude"):
                link = self.home / app / "skills" / skill.parent.name
                self.assertTrue(link.is_symlink())
                self.assertTrue((link / "SKILL.md").samefile(skill))
        reference = "codebase-study-pack/references/study-pack-structure.md"
        self.assertTrue((self.home / ".agents/skills" / reference).is_file())
        self.assertTrue((self.home / ".claude/skills" / reference).is_file())
        skill = self.source / "skills/minimal-coding/SKILL.md"
        skill.write_text(skill.read_text() + "\nLive change\n")
        for app in (".agents", ".claude"):
            self.assertIn("Live change", (self.home / app / "skills/minimal-coding/SKILL.md").read_text())
        self.install()
        self.assertFalse((self.home / ".local/state/agent-setup/backups").exists())

    def test_migration_preserves_customizations_and_unrelated_skills(self):
        canonical = self.source / "skills/minimal-coding"
        identical = self.write(".claude/commands/minimal-coding.md", (canonical / "SKILL.md").read_text())
        custom = self.write(".codex/skills/minimal-coding/SKILL.md", "local edits")
        self.write(".codex/skills/minimal-coding/notes.txt", "keep this too")
        self.write(".agents/skills/minimal-coding/SKILL.md", "newer shared edits")
        unrelated = self.write(".agents/skills/unrelated/SKILL.md", "unrelated")
        self.write(".claude/commands/unrelated.md", "unrelated command")
        external = self.root / "external"
        external.mkdir()
        (external / "SKILL.md").write_text("external skill")
        legacy = self.home / ".cursor/skills/minimal-coding"
        legacy.parent.mkdir(parents=True)
        legacy.symlink_to(external)
        broken = self.home / ".codex/prompts/minimal-coding.md"
        broken.parent.mkdir(parents=True)
        broken.symlink_to(self.root / "missing")
        result = self.install()
        self.assertFalse(identical.exists())
        self.assertFalse(custom.exists())
        self.assertFalse(legacy.is_symlink())
        self.assertFalse(broken.is_symlink())
        self.assertEqual((external / "SKILL.md").read_text(), "external skill")
        self.assertEqual(unrelated.read_text(), "unrelated")
        backups = list((self.home / ".local/state/agent-setup/backups").iterdir())
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / ".codex/skills/minimal-coding/SKILL.md").read_text(), "local edits")
        self.assertEqual((backups[0] / ".codex/skills/minimal-coding/notes.txt").read_text(), "keep this too")
        self.assertEqual((backups[0] / ".agents/skills/minimal-coding/SKILL.md").read_text(), "newer shared edits")
        self.assertIn(str(backups[0]), result.stdout)
        self.install()
        self.assertEqual(len(list(backups[0].parent.iterdir())), 1)

    def test_legacy_skill_root_alias_does_not_remove_shared_links(self):
        shared = self.home / ".agents/skills"
        shared.mkdir(parents=True)
        for app in (".codex", ".cursor"):
            root = self.home / app / "skills"
            root.parent.mkdir()
            root.symlink_to(shared)
        self.install()
        self.assertTrue((shared / "minimal-coding/SKILL.md").is_file())
        self.install()
        self.assertTrue((shared / "minimal-coding/SKILL.md").is_file())

    def test_removing_skill_cleans_only_its_managed_links(self):
        self.install()
        unrelated = self.home / ".agents/skills/external"
        unrelated.symlink_to(self.root / "missing-external")
        shutil.rmtree(self.source / "skills/find-skills")
        self.install()
        for app in (".agents", ".claude"):
            self.assertFalse((self.home / app / "skills/find-skills").is_symlink())
            self.assertTrue((self.home / app / "skills/current-work/SKILL.md").is_file())
        self.assertTrue(unrelated.is_symlink())

    def test_complete_resources_and_sibling_links_are_available(self):
        import re
        self.install()
        for app in (".agents", ".claude"):
            skill_root = self.home / app / "skills"
            for skill in self.skills:
                for source_file in skill.parent.rglob("*"):
                    if source_file.is_file():
                        installed = skill_root / skill.parent.name / source_file.relative_to(skill.parent)
                        self.assertTrue(installed.samefile(source_file), str(installed))
                for target in re.findall(r"\]\(([^)]+)\)", skill.read_text()):
                    if target.startswith("../"):
                        self.assertTrue((skill.parent / target).is_file(), target)
                        self.assertTrue((skill_root / skill.parent.name / target).is_file(), target)
        self.assertFalse((self.home / "bin/ticket").exists())
        self.assertFalse((self.home / ".zshrc").exists())

    def test_moving_checkout_repairs_links(self):
        self.install()
        destination = self.root / "moved checkout"
        self.source.rename(destination)
        self.source = destination
        self.install()
        self.assertTrue((self.home / ".agents/skills/minimal-coding/SKILL.md").samefile(self.source / "skills/minimal-coding/SKILL.md"))

    def test_invalid_skill_fails_before_changing_existing_install(self):
        existing = self.write(".agents/skills/minimal-coding/SKILL.md", "local")
        skill = self.source / "skills/minimal-coding/SKILL.md"
        skill.write_text(skill.read_text().replace("name: minimal-coding", "name: incorrect", 1))
        result = self.install(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(existing.read_text(), "local")
        self.assertFalse((self.home / "bin").exists())

    def test_piped_bootstrap_uses_persistent_checkout(self):
        tools = self.root / "tools"
        tools.mkdir()
        git = tools / "git"
        git.write_text('''#!/usr/bin/env bash
set -eu
printf '%s\\n' "$*" >> "$TEST_GIT_LOG"
if [[ "$1" == clone ]]; then
  cp -R "$TEST_SOURCE" "$3"
  mkdir "$3/.git"
elif [[ "$3" == remote ]]; then
  echo https://github.com/nguyenhoangminh1106/agent-setup.git
elif [[ "$3" == pull ]]; then
  exit 0
else
  exit 1
fi
''')
        git.chmod(0o755)
        self.env.update(PATH=str(tools) + os.pathsep + self.env["PATH"], TEST_SOURCE=str(self.source), TEST_GIT_LOG=str(self.root / "git.log"))
        self.install(piped=True)
        central = self.home / ".local/share/agent-setup"
        self.assertTrue((self.home / ".agents/skills/minimal-coding").samefile(central / "skills/minimal-coding"))
        self.install(piped=True)
        self.assertIn("pull --ff-only", (self.root / "git.log").read_text())


if __name__ == "__main__":
    unittest.main()
