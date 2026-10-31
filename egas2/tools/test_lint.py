"""Pass/fail fixtures for egas2/tools/lint.py. Run: python egas2/tools/test_lint.py"""
import sys, json, tempfile, pathlib, unittest
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import lint
from sysml_scan import EGAS2

CFG = json.loads((EGAS2 / "tools" / "kpi_config.json").read_text(encoding="utf-8"))
CFG["registry_enforced"] = True
HEADER = "| concept | kind | home package | legacy names | status | note |\n|---|---|---|---|---|---|\n"


def run(files, registry=""):
    with tempfile.TemporaryDirectory() as d:
        d = pathlib.Path(d)
        (d / "model").mkdir()
        for name, text in files.items():
            (d / "model" / name).write_text(text, encoding="utf-8")
        (d / "REGISTRY.md").write_text(HEADER + registry, encoding="utf-8")
        return lint.lint(d / "model", d / "REGISTRY.md", CFG)


def codes(out, sev="ERROR"):
    return sorted({o[0] for o in out if o[1] == sev})


def reg(*rows):
    return "".join(f"| {n} | part | {p} | none | {s} | x |\n" for n, p, s in rows)


GOAL = "package EgasArch_Needs_G {\n  @GoalData { kind = GoalKind::hard; }\n  requirement def G1 { }\n}\n"
HINT_REG = reg(("G1", "EgasArch_Needs_G", "active"), ("S1", "EgasArch_Scn_S", "active"))


class LintTests(unittest.TestCase):
    def test_clean_model_passes(self):
        out = run({"a.sysml": "package EgasArch_Common_A { part def Thing; }"}, reg(("Thing", "EgasArch_Common_A", "active")))
        self.assertEqual(out, [])

    def test_real_model_has_no_errors(self):
        out = lint.lint(EGAS2 / "model", EGAS2 / "memory" / "REGISTRY.md", CFG)
        self.assertEqual(codes(out), [], [o for o in out if o[1] == "ERROR"])

    def test_unregistered_definition(self):
        self.assertEqual(codes(run({"a.sysml": "package EgasArch_Common_A { part def Thing; }"})), ["L1"])

    def test_registry_home_mismatch_and_status(self):
        files = {"a.sysml": "package EgasArch_Common_A { part def Thing; }"}
        self.assertEqual(codes(run(files, reg(("Thing", "EgasArch_Common_B", "active")))), ["L2"])
        self.assertEqual(codes(run(files, reg(("Thing", "EgasArch_Common_A", "retired")))), ["L3"])
        self.assertEqual(codes(run(files, reg(("Thing", "EgasArch_Common_A", "planned"))), "WARNING"), ["L3"])
        self.assertEqual(codes(run(files, reg(("Thing", "EgasArch_Common_A", "bogus")))), ["L2"])

    def test_duplicate_definition_and_registry_row(self):
        files = {"a.sysml": "package EgasArch_Common_A { part def Thing; }", "b.sysml": "package EgasArch_Common_B { part def Thing; }"}
        self.assertIn("L2", codes(run(files, reg(("Thing", "EgasArch_Common_A", "active")))))
        row = reg(("Thing", "EgasArch_Common_A", "active"))
        self.assertIn("L2", codes(run({"a.sysml": files["a.sysml"]}, row + row)))

    def test_upward_import_and_cycle(self):
        up = {"c.sysml": "package EgasArch_Common_C { private import EgasArch_Needs_N::*; }", "n.sysml": "package EgasArch_Needs_N { }"}
        self.assertEqual(codes(run(up)), ["L4"])
        cyc = {"a.sysml": "package EgasArch_Common_A { private import EgasArch_Common_B::*; }",
               "b.sysml": "package EgasArch_Common_B { private import EgasArch_Common_A::*; }"}
        self.assertEqual(codes(run(cyc)), ["L4"])
        ok = {"a.sysml": "package EgasArch_Common_A { private import EgasArch_Common_B::*; }", "b.sysml": "package EgasArch_Common_B { }"}
        self.assertEqual(run(ok), [])

    def test_relationship_placement(self):
        sat = "package EgasArch_{L}_X {{ satisfy R by T; }}"
        self.assertEqual(codes(run({"x.sysml": sat.format(L="Scn")})), ["L5"])
        self.assertEqual(run({"x.sysml": sat.format(L="Fbb")}), [])
        self.assertEqual(codes(run({"x.sysml": "package EgasArch_Fbb_X { allocate A to B; }"})), ["L5"])
        self.assertEqual(run({"x.sysml": "package EgasArch_Lwb_X { allocate A to B; }"}), [])
        self.assertEqual(codes(run({"x.sysml": "package EgasArch_Beh_X { #derivation connection { } }"})), ["L5"])
        self.assertEqual(codes(run({"x.sysml": "package EgasArch_Sysr_X { #refinement dependency a to b; }"})), ["L5"])

    def test_blackbox_purity(self):
        bad = "package EgasArch_Ctx_X { part def EgasSystem { port p : P; part inner : I; } }"
        self.assertEqual(codes(run({"x.sysml": bad}, reg(("EgasSystem", "EgasArch_Ctx_X", "active")))), ["L6"])
        good = "package EgasArch_Ctx_X { part def EgasSystem { port p : P; doc /* ok */ } }"
        self.assertEqual(run({"x.sysml": good}, reg(("EgasSystem", "EgasArch_Ctx_X", "active"))), [])

    def test_value_provenance(self):
        meta = "  @SourceRef { document = \"d\"; }\n  @ValueStatus { status = ValueStatusKind::project; }\n"
        self.assertEqual(run({"x.sysml": "package EgasArch_Common_X {\n" + meta + "  attribute n : Integer = 3;\n}"}), [])
        self.assertEqual(codes(run({"x.sysml": "package EgasArch_Common_X {\n  attribute n : Integer = 3;\n}"})), ["L8"])
        half = "package EgasArch_Common_X {\n  @SourceRef { document = \"d\"; }\n  attribute n : Integer = 3;\n}"
        self.assertEqual(codes(run({"x.sysml": half})), ["L8"])

    def test_scenario_and_goal_hints(self):
        scn = ('package EgasArch_Scn_S {{\n  @ScenarioData {{ kind = ScenarioKind::main; {body} }}\n  use case def S1 {{ }}\n}}\n')
        full = 'fulfills = ("G1"); preCondition = "a"; postCondition = "b";'
        self.assertEqual(run({"g.sysml": GOAL, "s.sysml": scn.format(body=full)}, HINT_REG), [])
        self.assertEqual(codes(run({"g.sysml": GOAL, "s.sysml": scn.format(body='fulfills = ("G1");')}, HINT_REG)), ["L7"])
        self.assertEqual(codes(run({"g.sysml": GOAL, "s.sysml": scn.format(body='fulfills = ("G9"); preCondition = "a"; postCondition = "b";')}, HINT_REG)), ["L7"])
        self.assertEqual(codes(run({"g.sysml": GOAL}, HINT_REG)), ["L7"])


if __name__ == "__main__":
    unittest.main(verbosity=1)
