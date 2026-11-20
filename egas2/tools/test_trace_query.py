"""Fixtures for egas2/tools/trace_query.py. Run: python egas2/tools/test_trace_query.py"""
import sys, io, contextlib, shutil, tempfile, pathlib, unittest
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import syside
import trace_query as tq
from sysml_scan import EGAS2, sysml_files

SAT = "satisfy sysrTorqueComparison by logicalEgasWb.l2Monitor;"
SAT2 = "satisfy sysrExcessConfirmation by logicalEgasWb.l2Monitor;"
SAT3 = "satisfy sysrThrottleSensorFaultDetection by logicalEgasWb.l2Monitor;"


def load(model_dir):
    return syside.try_load_model(paths=[str(f) for f in sysml_files(pathlib.Path(model_dir))])


def rows_of(model, fn, *extra):
    return {r[0]: r for r in fn(tq.Graph(model), *extra)}


class TraceQueryTests(unittest.TestCase):
    def test_real_model_has_complete_chain(self):
        model, diags = load(EGAS2 / "model")
        self.assertEqual(sum(1 for _ in diags.errors), 0)
        g = tq.Graph(model)
        self.assertEqual(tq.aq1(g)[0][3], "LC not reached: -")
        self.assertEqual(tq.aq3(g)[0][2], "UF without satisfy: -; LC without satisfy: -")
        self.assertIn(f"SYSR verified {len(g.sysr)}/{len(g.sysr)}", tq.aq6(g)[0][1])
        self.assertEqual(len(g.fsr), 5)
        self.assertTrue(tq.aq1(g)[0][1].startswith("FSR 5,"))
        self.assertIn("FSR verified 5/5", tq.aq6(g)[0][1])
        self.assertIn("SHR validated 6/6", tq.aq6(g)[0][1])

    def test_removed_satisfy_is_reported(self):
        with tempfile.TemporaryDirectory() as d:
            copy = pathlib.Path(d) / "model"
            shutil.copytree(EGAS2 / "model", copy)
            f = copy / "03_Logical" / "EgasArch_Lwb_Logical.sysml"
            f.write_text(f.read_text(encoding="utf-8").replace(SAT, "").replace(SAT2, "").replace(SAT3, ""), encoding="utf-8")
            model, _ = load(copy)
            self.assertIn("LC without satisfy: l2Monitor", tq.aq3(tq.Graph(model))[0][2])

    def test_diagnostics_reports_errors(self):
        model, diags = syside.try_load_model(sysml_source="package EgasArch_Common_Bad { part x : NoSuchType; }")
        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(tq.diagnostics(diags), 1)
        self.assertIn("reference-error", out.getvalue())


if __name__ == "__main__":
    unittest.main()
