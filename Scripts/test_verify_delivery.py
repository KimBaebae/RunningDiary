import unittest
from verify_delivery import verify_ci, verify_identity, verify_testflight_run

SHA = "a" * 40


def ci_run(**changes):
    run = dict(id=10, run_attempt=1, head_sha=SHA, head_branch="main", event="push",
               path=".github/workflows/build-and-test.yml", status="completed", conclusion="success")
    return run | changes


def upload_run(**changes):
    return ci_run(event="workflow_dispatch", path=".github/workflows/testflight.yml") | changes


class DeliveryEvidenceTests(unittest.TestCase):
    def test_accepts_successful_exact_main_candidate(self):
        for event in ("push", "workflow_dispatch"):
            verify_ci({"workflow_runs": [ci_run(event=event)]}, SHA)

    def test_rejects_wrong_candidate_branch_event_workflow_or_missing_ci(self):
        for changes in ({"head_sha": "b" * 40}, {"head_branch": "feature/test"},
                        {"event": "pull_request"}, {"path": "other.yml"}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                verify_ci({"workflow_runs": [ci_run(**changes)]}, SHA)
        with self.assertRaises(ValueError):
            verify_ci({"workflow_runs": []}, SHA)

    def test_old_success_cannot_mask_new_failure_or_running_attempt(self):
        for status, conclusion in (("completed", "failure"), ("in_progress", None)):
            with self.subTest(status=status), self.assertRaises(ValueError):
                verify_ci({"workflow_runs": [ci_run(), ci_run(id=11, status=status, conclusion=conclusion)]}, SHA)

    def test_accepts_exact_uploaded_build(self):
        run = upload_run()
        verify_testflight_run(run, "10")
        verify_identity(dict(sha=SHA, version="1.2.0", build="42", run_id="10", run_attempt="1"),
                        run, SHA, "1.2.0", "42")

    def test_rejects_wrong_upload_or_failed_attempt(self):
        for changes in ({"conclusion": "failure"}, {"event": "push"},
                        {"head_branch": "release/v1.2.0"}, {"id": 11},
                        {"path": ".github/workflows/release.yml"}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                verify_testflight_run(upload_run(**changes), "10")

    def test_rejects_identity_mismatch_and_stale_artifact_after_rerun(self):
        original = dict(sha=SHA, version="1.2.0", build="42", run_id="10", run_attempt="1")
        for field, value in (("sha", "b" * 40), ("version", "1.3.0"), ("build", "43"),
                             ("run_id", "11"), ("run_attempt", "2")):
            with self.subTest(field=field), self.assertRaises(ValueError):
                verify_identity(original | {field: value}, upload_run(), SHA, "1.2.0", "42")
        with self.assertRaises(ValueError):
            verify_identity(original, upload_run(run_attempt=2), SHA, "1.2.0", "42")


if __name__ == "__main__":
    unittest.main()
