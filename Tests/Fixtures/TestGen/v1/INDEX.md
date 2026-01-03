# TestGen v1 Fixture Corpus Index

## Quick Start

```bash
# Run all tests
python Tests/Fixtures/TestGen/test_harness.py

# Run golden tests only (CI)
python Tests/Fixtures/TestGen/test_harness.py --golden-only

# Load a specific fixture
python -c "import json; print(json.load(open('Tests/Fixtures/TestGen/v1/validators/all_of_the_above.json')))"
```

## Directory Structure

```
Tests/Fixtures/TestGen/v1/
├── schema/          (16) JSON parsing & schema drift
├── validators/      (27) MCQ structure & content policy  
├── regeneration/    (5)  Retry & repair behavior
├── distribution/    (5)  Answer key patterns
├── unicode/         (6)  Formatting adversaries
├── golden/          (2)  Known good regression tests
├── README.md        Detailed manifest
└── test_harness.py  Automated test runner

Total: 60+ fixtures
```

## Categories at a Glance

### Schema (16 fixtures)
JSON parsing, type validation, version control, strict decoding

### Validators (27 fixtures)
MCQ structure, banned phrases, duplicates, topic scope, prompt/rationale constraints

### Regeneration (5 fixtures)
Retry logic, failure recovery, max attempts, safe fallback

### Distribution (5 fixtures)
Answer key pattern detection, balance checking

### Unicode (6 fixtures)
Zero-width chars, RTL marks, smart quotes, emoji, newlines

### Golden (2 fixtures)
5Q mini test, 20Q full test - MUST always pass

## Key Files

- `README.md` - Complete fixture manifest with usage examples
- `test_harness.py` - Automated test runner with validation mock
- `TESTGEN_FIXTURE_CORPUS_SUMMARY.md` - Implementation summary

## Fixture Format

```json
{
  "description": "What this tests",
  "category": "Category name",
  "severity": "fatal|warning|info",
  "input": "LLM output",
  "expected": {
    "status": "pass|fail|warn",
    "error_code": "ERROR_CODE",
    "should_trigger_regeneration": true|false
  },
  "notes": "Context and rationale"
}
```

## Common Error Codes

| Code | Category | Severity |
|------|----------|----------|
| `INVALID_JSON` | Schema | Fatal |
| `MISSING_CONTRACT_VERSION` | Schema | Fatal |
| `INVALID_CHOICE_COUNT` | MCQ | Fatal |
| `DUPLICATE_CHOICES` | MCQ | Fatal |
| `BANNED_PHRASE_ALL_OF_ABOVE` | Content | Fatal |
| `DISTRIBUTION_ALL_SAME_ANSWER` | Distribution | Fatal |
| `PROMPT_TOO_LONG` | Content | Fatal |
| `ABSOLUTE_LANGUAGE_DETECTED` | Content | Warning |

## Testing Workflow

1. **Load Fixture**
   ```python
   fixture = load_fixture("validators", "all_of_the_above")
   ```

2. **Run Validation**
   ```python
   result = validator.validate(fixture["input"])
   ```

3. **Check Results**
   ```python
   assert result.status == fixture["expected"]["status"]
   assert result.error_code == fixture["expected"]["error_code"]
   ```

4. **Add New Bug Case**
   - Create fixture JSON
   - Run test to verify it fails
   - Fix validator
   - Verify test now passes

## CI Integration

```yaml
# .github/workflows/testgen.yml
- name: Golden Fixture Regression Test
  run: python Tests/Fixtures/TestGen/test_harness.py --golden-only
  # Fails CI if golden tests fail

- name: All Fixture Tests
  run: python Tests/Fixtures/TestGen/test_harness.py
  # Reports results
```

## Coverage Goals

- [x] JSON parsing - 100%
- [x] Schema validation - 100%
- [x] MCQ structure - 100%
- [x] Content policy - 100%
- [x] Regeneration - 100%
- [x] Distribution - 100%
- [x] Unicode handling - 100%
- [x] Golden regression - Yes

## Never-Ship-Invalid Guarantee

Every validation branch is covered by fixtures:
✅ All malformed JSON caught
✅ All schema violations caught
✅ All banned constructs caught
✅ All MCQ errors caught
✅ Regeneration tested
✅ Safe fallback tested

## Quick Reference

### Most Critical Fixtures

1. `golden/bio101_5q_mini.json` - Must always pass
2. `golden/bio101_20q_full.json` - Must always pass
3. `validators/all_of_the_above.json` - Common LLM mistake
4. `schema/non_json_text.json` - LLM refuses to generate
5. `regeneration/max_retries_exhausted.json` - Fallback path

### Adding a New Fixture

```bash
# 1. Create fixture
cat > Tests/Fixtures/TestGen/v1/validators/my_case.json << 'EOF'
{
  "description": "Description",
  "category": "category",
  "severity": "fatal",
  "input": "...",
  "expected": {"status": "fail", "error_code": "..."},
  "notes": "Why this matters"
}
EOF

# 2. Test it
python Tests/Fixtures/TestGen/test_harness.py

# 3. Commit
git add Tests/Fixtures/TestGen/v1/validators/my_case.json
git commit -m "Add fixture for [bug description]"
```

## Documentation

- `README.md` - Full manifest with all fixtures
- `TESTGEN_FIXTURE_CORPUS_SUMMARY.md` - Implementation guide
- `test_harness.py` - Inline code documentation
- This file - Quick reference index

## Contact

Questions about fixtures? See:
1. README.md for detailed descriptions
2. test_harness.py for usage examples
3. Existing fixtures for patterns

## Version

- **Fixture Version**: v1
- **TestGen Contract**: 1.0
- **Total Fixtures**: 60+
- **Last Updated**: 2026-01-03
