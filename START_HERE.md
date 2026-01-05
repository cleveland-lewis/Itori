# Production Prep: Start Here

**Date:** 2026-01-05  
**Current State:** 60% production-ready  
**Time to Ship:** 1 week (fast track) or 2-3 weeks (full feature set)

---

## What Just Happened

Your audit revealed the gap between "mostly done" and "production-ready." The system is solid but accumulating design debt (47 TODOs, 60+ backup files, incomplete features).

Instead of more analysis, I built **mechanical enforcement**:
- Scripts that fail if code is dirty
- CI pipeline that runs them
- Binary checklists that remove guesswork
- Documentation that defines "done"

---

## Artifacts Created

### Gate Documents
1. **PRODUCTION_PREP.md** — The canonical checklist (what "ready" means)
2. **RELEASE_SCOPE_v1.md** — Feature freeze (what's in/out)
3. **PRODUCTION_PREP_EXECUTION.md** — Day-by-day execution plan

### Enforcement Scripts
4. **Scripts/check_release_hygiene.sh** (enhanced) — Catches backup files, TODOs, conflicts
5. **Scripts/check_threading_safety.sh** (new) — Detects @Published without @MainActor
6. **Scripts/check_version_sync.sh** (new) — Verifies VERSION/CHANGELOG exist

### CI Pipeline
7. **.github/workflows/ci.yml** (updated) — Runs all gates on every PR

### Audit Frameworks
8. **Docs/THREADING_AUDIT.md** — Threading safety checklist
9. **Docs/LAYOUT_STRESS_RESULTS.md** — Layout stress test matrix
10. **Docs/ERROR_STATE_AUDIT.md** — Empty/error state audit
11. **Docs/ICLOUD_SYNC_STRATEGY.md** — Conflict resolution strategy

### Version Discipline
12. **VERSION** — Current version (1.0.0)
13. **CHANGELOG.md** — Release notes template
14. **BACKLOG.md** — Deferred features (v1.1+)

---

## What the Scripts Found (Baseline)

```
❌ 1 .orig file (merge conflict residue)
❌ 60+ .backup files (unstable codebase indicator)
⚠️ 39 force unwraps in critical paths (potential crashes)
⚠️ 44 untracked TODOs (decision fatigue)
```

---

## Your Two Options

### Option 1: Fast Track (1 Week)
**Ship with smaller scope, same discipline.**

**Actions:**
1. Remove activeSemesterIds (incomplete UI)
2. Remove TaskAlarmScheduler (5 TODOs)
3. Delete backup files
4. Audit TODOs (convert or remove)
5. Add @MainActor to AppModel
6. Run stress tests
7. Ship v1.0

**Result:** Production-ready app, smaller feature set, explicit constraints.

---

### Option 2: Full Path (2-3 Weeks)
**Finish all features, full hardening.**

**Additional Work:**
- Complete activeSemesterIds UI (2-3 days)
- Complete TaskAlarmScheduler (2-3 days)
- Add snapshot tests (1-2 days)
- Advanced error handling (2 days)

**Result:** Feature-complete v1.0, longer timeline.

---

## Immediate Next Steps (Start Now)

### 1. Run Baseline Check
```bash
cd /Users/clevelandlewis/Desktop/Itori
bash Scripts/check_release_hygiene.sh | tee hygiene_baseline.txt
bash Scripts/check_threading_safety.sh | tee threading_baseline.txt
```

### 2. Choose Your Path
Read `RELEASE_SCOPE_v1.md` and decide:
- Fast track (cut features), or
- Full path (finish features)

### 3. Execute Day 1 (4 hours)
Follow `PRODUCTION_PREP_EXECUTION.md`:
- Delete backup files (15 min)
- Audit 44 TODOs (2-3 hours)
- Apply feature cuts if fast track (1 hour)

### 4. Verify CI Works
```bash
git checkout -b production-prep
git add .
git commit -m "chore: production prep enforcement system"
git push origin production-prep
# Open PR, watch CI run
```

---

## The Meta-Point

You asked for "the shape of production prep." Here it is:

**Not a narrative—a machine.**

Every item in PRODUCTION_PREP.md maps to:
- A script that fails if violated, OR
- A test that catches regressions, OR
- A manual checklist with binary pass/fail

Once these gates are green, "production prep is done" becomes mechanical, not aspirational.

---

## Cultural Shift

**Before:** Intuition-driven development (add features, fix bugs, iterate)  
**After:** Constraint-driven development (every change must justify blast radius)

The scripts enforce this. When a TODO without an issue breaks CI, or a backup file fails hygiene, the system becomes "slightly annoying to change"—and that's when you know it's stabilizing.

---

## Success Criteria

**You're ready when:**
- All scripts pass
- CI is green
- Manual QA complete
- Gate documents signed off

**You know it's working when:**
- Merging requires no manual gate-keeping
- CI catches problems before you do
- Making a change feels "slightly annoying" (constraints enforced)

---

## Questions?

**"Can I skip X?"** → Check PRODUCTION_PREP.md. If it has ❌ (CRITICAL), no. If ⚠️ (HIGH), risky but possible.

**"How do I know I'm done?"** → All checkboxes in PRODUCTION_PREP.md are ✅.

**"What if CI fails?"** → Fix it. That's the point—it catches problems mechanically.

---

## Final Advice

Don't overthink. Execute the plan:
1. Choose fast track or full path (30 min)
2. Delete backup files (15 min)
3. Audit TODOs (2-3 hours)
4. Run scripts (5 min)
5. Repeat until green

By end of week, you'll have a production-ready app with mechanical quality gates.

---

**Next File to Read:** `PRODUCTION_PREP_EXECUTION.md` (the day-by-day plan)
