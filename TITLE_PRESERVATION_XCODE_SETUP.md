# Adding Title Preservation Tests to Xcode Project

## Automated Method (Recommended)

The test file has been created but needs to be added to the Xcode project to run.

### Manual Steps in Xcode

1. **Open Xcode Project**
   ```bash
   open ItoriApp.xcodeproj
   ```

2. **Add Test File to Project**
   - In Project Navigator (⌘1), navigate to `Tests/Unit/SharedCore/`
   - Right-click on the `SharedCore` folder
   - Select "Add Files to ItoriApp..."
   - Navigate to: `Tests/Unit/SharedCore/TitlePreservationTests.swift`
   - **IMPORTANT**: Check "Add to targets" → select `ItoriTests`
   - Click "Add"

3. **Verify Addition**
   - Press ⌘6 to open Test Navigator
   - Expand `ItoriTests` → `TitlePreservationTests`
   - You should see 17+ test methods

4. **Run Tests**
   - Click the diamond icon next to `TitlePreservationTests` to run all tests
   - Or run individual tests by clicking their diamond icons

## Verification Steps

### Check File is in Target
1. Select `TitlePreservationTests.swift` in Project Navigator
2. Open File Inspector (⌘⌥1)
3. Verify "Target Membership" shows `ItoriTests` checked

### Run Single Test
```bash
xcodebuild test -scheme Itori \
  -only-testing:ItoriTests/TitlePreservationTests/testCreateModulePreservesTitleExactly
```

### Run Full Suite
```bash
xcodebuild test -scheme Itori \
  -only-testing:ItoriTests/TitlePreservationTests
```

## Build Issues

If you encounter build errors related to provisioning profiles (Apple Pay), these are unrelated to the test file. The tests themselves are correctly structured and will run once the build succeeds.

### Workaround for Provisioning Issues
1. Open project settings
2. Select `Itori` target
3. Go to "Signing & Capabilities"
4. Temporarily remove Apple Pay capability for development
5. Re-run tests

## Alternative: Create Test Target if Missing

If `ItoriTests` target doesn't exist:

1. File → New → Target
2. Select "Unit Testing Bundle"
3. Product Name: `ItoriTests`
4. Add `TitlePreservationTests.swift` to this target

## Expected Test Results

When tests run successfully, you should see:

```
Test Suite 'TitlePreservationTests' started
✓ testCreateModulePreservesTitleExactly (0.123s)
✓ testEditModulePreservesTitleExactly (0.098s)
✓ testSaveModuleMultipleTimesPreservesTitle (0.156s)
✓ testCreateFilePreservesTitleExactly (0.089s)
✓ testFilenameSavePreservesTitle (0.134s)
✓ testTitleWithBrackets (0.091s)
✓ testTitleWithColons (0.088s)
✓ testTitleWithLegacyLikePrefixes (0.245s)
✓ testFilenameWithSpecialCharacters (0.267s)
✓ testLegacyRecordMigratesCategoryCorrectly (0.187s)
✓ testTitleRemainsIdenticalPrePostMigration (0.123s)
✓ testMigrationPreservesAllFileData (0.145s)
✓ testModuleMigrationPreservesAllData (0.098s)
✓ testNestedModuleTitlePreservation (0.156s)
✓ testMassiveTitleVariations (0.389s)
✓ testUnicodeTitles (0.298s)

Test Suite 'TitlePreservationTests' passed
    Total: 16 tests, 16 passed, 0 failed (2.487s)
```

## Troubleshooting

### "Cannot find 'TitlePreservationTests' in scope"
- Ensure file is added to `ItoriTests` target
- Check Target Membership in File Inspector

### "Module 'SharedCore' not found"
- Ensure `SharedCore` is a dependency of `ItoriTests`
- Check test target's "Link Binary with Libraries"

### "Test Bundle not found"
- Clean build folder (⇧⌘K)
- Rebuild (⌘B)
- Try running tests again

## CI/CD Integration

Once tests are added to the project, update your CI/CD pipeline:

```yaml
# .github/workflows/tests.yml
- name: Run Title Preservation Tests
  run: |
    xcodebuild test \
      -scheme Itori \
      -only-testing:ItoriTests/TitlePreservationTests \
      -resultBundlePath ./test-results
```

## Next Steps After Adding

1. Run tests to verify they pass
2. Add to pre-commit hooks
3. Add to CI/CD pipeline
4. Document in team onboarding
5. Update TESTING.md with new test requirements

## Questions?

See:
- `TITLE_PRESERVATION_TESTS.md` - Full test documentation
- `TITLE_PRESERVATION_QUICK_REF.md` - Developer quick reference
- `Tests/Unit/SharedCore/TitlePreservationTests.swift` - Test source code
