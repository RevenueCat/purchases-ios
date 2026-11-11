import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name('download_predicate_conformance_fixtures.sh')
FIXTURE = Path('khepri/services/audience/fixtures/predicate_conformance_v1.json')


class DownloadConformanceTest(unittest.TestCase):
    def test_downloads_exact_commit_and_rejects_invalid_cases(self):
        self.assertTrue(SCRIPT.exists(), 'The exact-commit downloader is missing')
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            upstream = root / 'khepri'
            subprocess.run(['git', 'init', '-q', str(upstream)], check=True)
            fixture = upstream / FIXTURE
            fixture.parent.mkdir(parents=True)
            env = os.environ | {
                'GIT_AUTHOR_NAME': 'Test', 'GIT_AUTHOR_EMAIL': 'test@example.com',
                'GIT_COMMITTER_NAME': 'Test', 'GIT_COMMITTER_EMAIL': 'test@example.com',
                'GIT_CONFIG_COUNT': '1',
                'GIT_CONFIG_KEY_0': f'url.file://{upstream}.insteadOf',
                'GIT_CONFIG_VALUE_0': 'git@github.com:RevenueCat/khepri.git',
            }
            valid = {'schema_version': 1, 'kind': 'audience_predicate', 'fixtures': [
                {'id': 'khepri/test', 'predicate': True, 'variables': {}, 'expected': True},
            ]}
            fixture.write_text(json.dumps(valid))
            subprocess.run(['git', '-C', str(upstream), 'add', '.'], check=True, env=env)
            subprocess.run(['git', '-C', str(upstream), 'commit', '-qm', 'valid'], check=True, env=env)
            sha = subprocess.check_output(['git', '-C', str(upstream), 'rev-parse', 'HEAD'], text=True).strip()
            fixture.write_text('{"fixtures": []}')
            subprocess.run(['git', '-C', str(upstream), 'commit', '-qam', 'invalid'], check=True, env=env)
            invalid_sha = subprocess.check_output(['git', '-C', str(upstream), 'rev-parse', 'HEAD'], text=True).strip()
            destination = root / 'output' / 'cases.json'
            destination.parent.mkdir()
            destination.write_text('stale')
            subprocess.run(['bash', str(SCRIPT), sha, str(destination)], check=True, env=env, capture_output=True)
            self.assertEqual(json.loads(destination.read_text()), valid)
            for ref in ['main', '0' * 40, invalid_sha]:
                with self.subTest(ref=ref):
                    result = subprocess.run(['bash', str(SCRIPT), ref, str(destination)], env=env, capture_output=True)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(json.loads(destination.read_text()), valid)


if __name__ == '__main__':
    unittest.main()
