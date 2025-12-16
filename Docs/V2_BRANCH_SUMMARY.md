# Practice Testing v2 Research Branch - Summary

**Date Created**: December 16, 2025  
**Branch**: `practice_test_generation_v2`  
**Status**: 🔬 Planning Phase Complete  
**Base**: Practice Testing v1 (main branch)

---

## Overview

A new research branch has been created containing comprehensive planning documents for Practice Testing v2. This branch implements the previously deferred "non-goals" from v1:

1. **Item Response Theory (IRT)** - Psychometric modeling
2. **Adaptive Testing** - Real-time difficulty adjustment  
3. **Calibrated Question Banks** - Large-scale item repositories
4. **Multi-Student Calibration** - Privacy-safe collaborative parameter estimation

---

## What's in the Branch?

### Documentation Files

**V2_RESEARCH_README.md** (Root)
- Comprehensive overview of v2 features
- Implementation phases (8 phases over 12 months)
- Success criteria and validation requirements
- Privacy & ethics considerations
- Budget ($180k) and resource requirements
- Clear warnings about research-only status

**Docs/PRACTICE_TESTING_V2_ROADMAP.md**
- Technical architecture and data models
- Blueprint-first generation flow
- IRT model specifications (1PL, 2PL, 3PL)
- Adaptive algorithm design
- Item bank management
- Multi-student calibration protocol
- Risk register and mitigation strategies
- 20+ pages of detailed roadmap

**Docs/V2_RESEARCH_PLAN.md**
- Detailed implementation plan with code examples
- Phase-by-phase deliverables
- Swift code samples for:
  - IRT models (ThreeParameterLogistic)
  - Ability estimation (MLE, EAP)
  - EM algorithm for calibration
  - Adaptive test engine
  - Exposure control strategies
- Research questions and hypotheses
- Validation study design
- Budget breakdown
- Timeline (Gantt chart)
- 30+ pages of research protocol

### Key Statistics

**Documentation**:
- 3 major documents created
- ~60+ pages total
- ~30,000+ words
- Comprehensive code examples
- Full research protocol

**Planning Complete**:
- ✅ 8 implementation phases defined
- ✅ 12-month timeline established
- ✅ ~$180k budget calculated
- ✅ Team requirements specified (3-5 people)
- ✅ Success criteria documented
- ✅ Risk mitigation planned

---

## Why This is a Research Branch

### ⚠️ NOT FOR PRODUCTION

This branch is **research-only** and will **NOT** be merged to main until:

1. **IRB Approval** - Ethical review board approval obtained
2. **Validation Study** - Completed with n > 1,000 students
3. **Psychometric Validation** - Correlation with paper tests > 0.85
4. **Privacy Audit** - Independent privacy review passed
5. **User Acceptance** - User satisfaction > 4.0/5.0
6. **Research Publication** - At least one peer-reviewed paper

### Complexity

v2 introduces significant complexity:

**Technical**:
- Advanced statistics (IRT, MML, EM algorithm)
- Complex algorithms (adaptive selection, exposure control)
- Large-scale data infrastructure (10,000+ items, 10,000+ users)

**Psychometric**:
- Model fit assessment (RMSEA, CFI)
- Parameter estimation (a, b, c)
- Differential Item Functioning (DIF)
- Equating procedures

**Privacy**:
- Differential privacy for aggregates
- FERPA/COPPA compliance
- Anonymous data pipelines
- Regular privacy audits

**Ethical**:
- Algorithmic fairness
- Test anxiety concerns
- Educational equity
- Assessment validity

---

## Implementation Timeline

### 12-Month Plan

```
Month  | Phase | Focus
-------|-------|------
1-2    | 1     | IRT Foundation (models, estimation, information)
2-4    | 2     | Item Calibration Pipeline (EM, model fit, privacy)
4-6    | 3     | Item Bank Management (schema, queries, versioning)
6-9    | 4     | Adaptive Test Engine (selection, exposure, termination)
5-6    | 5     | UI/UX for Adaptive Testing
6-8    | 6     | Multi-Student Calibration (aggregation, DIF, equating)
8-10   | 7     | Research Validation (n > 1000, analysis, paper)
10-12  | 8     | Production Integration (flags, rollout, monitoring)
```

### Key Milestones

- **Month 1**: IRB submission
- **Month 2**: IRT models validated vs R/ltm
- **Month 4**: First item calibrated
- **Month 6**: Item bank operational (1000+ items)
- **Month 9**: Adaptive engine complete
- **Month 10**: Validation study launched
- **Month 12**: Results analyzed, paper submitted

---

## Budget & Resources

### Personnel (~$220k/year)

- **Lead Researcher** (PhD, Psychometrics): 0.5 FTE - $75k
- **Senior Software Engineer**: 1.0 FTE - $120k
- **Research Assistant** (Graduate student): 0.5 FTE - $25k
- **Privacy/Ethics Consultant**: 40 hours - $8k
- **Statistical Consultant**: 20 hours - $4k

### Infrastructure (~$7k)

- Cloud compute for calibration: $6k/year
- Statistical software licenses (R, Mplus): $1k

### Research (~$12k)

- IRB fees: $2k
- Participant incentives: $10k (n=1000 @ $10 each)

### Total: ~$180k

---

## Success Criteria

### Technical ✅

- [ ] IRT model fit (RMSEA < 0.08, CFI > 0.95)
- [ ] Adaptive testing reduces length by 40-60%
- [ ] Ability estimates converge (SEM < 0.3)
- [ ] Item bank scales to 10,000+ items
- [ ] Privacy audit passed

### Psychometric ✅

- [ ] Correlation with paper tests > 0.85
- [ ] Test-retest reliability > 0.80
- [ ] No significant DIF detected
- [ ] Equating error < 0.3 SD

### User Experience ✅

- [ ] User satisfaction > 4.0/5.0
- [ ] Students report fairness
- [ ] Teachers find analytics useful
- [ ] Test anxiety not increased
- [ ] 80%+ completion rate

### Research ✅

- [ ] IRB approval obtained
- [ ] Validation study completed (n > 1000)
- [ ] At least one peer-reviewed publication
- [ ] Results replicated

---

## Privacy & Ethics

### Privacy-First Design

**Principles**:
1. **Local-First** - Sensitive data on device only
2. **Aggregation-Only** - Anonymous aggregate data only
3. **Opt-In** - Explicit consent required
4. **Transparency** - Clear data use explanations
5. **Right to Delete** - Users can withdraw anytime

**Implementation**:
- Differential privacy for aggregates (ε = 1.0)
- No PII in calibration data
- Regular privacy audits
- FERPA/COPPA compliant

### Ethical Concerns

**Fairness**:
- DIF detection mandatory
- Regular bias audits
- Diverse validation samples

**Equity**:
- Offline mode full-featured
- No "pay-to-win" features
- Free and accessible

**Validity**:
- Teacher judgment primary
- Tests are practice, not grades
- Clear limitations communicated

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Small sample sizes | Medium | High | Partner with schools early, use Bayesian priors |
| Privacy concerns | Medium | High | Differential privacy, clear consent, opt-in only |
| Model doesn't fit | Low | High | Test multiple models, accept some misfit |
| Adoption resistance | Medium | Medium | v1 remains default, v2 opt-in |
| Timeline overrun | High | Medium | Phased delivery, each phase standalone |
| Regulations change | Low | High | Follow strictest standards, modular design |

---

## Non-Goals (Even for v2)

### Out of Scope

- ❌ High-stakes summative assessment
- ❌ Teacher evaluation/accountability
- ❌ Commercial question marketplace
- ❌ Blockchain/cryptocurrency
- ❌ Gamification with leaderboards
- ❌ Social features

### Deferred to v3+

- ❌ Multi-modal items (video, simulation)
- ❌ Open-ended essay scoring (NLP)
- ❌ Cross-lingual equating
- ❌ Longitudinal growth modeling
- ❌ Collaborative test-taking

---

## Branch Management

### Current Status

```bash
# Branch info
git branch -v
* main                          506db0d hotfix: Fix Timer/Flashcards tab crash
  practice_test_generation_v2   e0b6a47 Add comprehensive README for v2 research branch

# Commits in v2 not in main
git log --oneline main..practice_test_generation_v2
e0b6a47 Add comprehensive README for v2 research branch
d529fd6 Add Practice Testing v2 research planning documents
```

### Files in v2 Branch

**New Documentation**:
- `V2_RESEARCH_README.md` (root)
- `Docs/PRACTICE_TESTING_V2_ROADMAP.md`
- `Docs/V2_RESEARCH_PLAN.md`

**No Code Changes Yet** - This is a planning branch only.

### Branch Protection

This branch should be protected with:
- ✅ No direct merges to main without approval
- ✅ Require IRB approval before merge
- ✅ Require validation study completion
- ✅ Require privacy audit
- ✅ Require research publication

---

## Next Steps

### Immediate (Week 1-2)

1. **Form Research Team**
   - Hire/recruit psychometrician
   - Identify privacy consultant
   - Recruit research assistant

2. **IRB Submission**
   - Prepare protocol
   - Submit to institutional review board
   - Await approval (typically 4-8 weeks)

3. **Partner Recruitment**
   - Identify schools for pilot
   - Negotiate data sharing agreements
   - Plan recruitment strategy

### Short-Term (Month 1-2)

4. **Phase 1: IRT Foundation**
   - Implement 3PL model
   - Develop ability estimators
   - Validate against R/ltm
   - 50+ unit tests

5. **Literature Review**
   - Review latest IRT research
   - Study adaptive testing algorithms
   - Examine privacy-preserving methods

### Medium-Term (Month 3-6)

6. **Phase 2-3: Calibration & Banks**
   - Build calibration pipeline
   - Implement item bank
   - Begin pilot data collection
   - 100+ items calibrated

### Long-Term (Month 7-12)

7. **Phase 4-8: Adaptive, Validation, Production**
   - Implement adaptive engine
   - Run validation study (n > 1000)
   - Analyze results
   - Prepare for production

---

## FAQ

### Q: When will v2 be ready?
**A**: Minimum 12 months, likely longer. This is research, not a product feature.

### Q: Will v1 still be supported?
**A**: Yes! v1 remains the production system. v2 is experimental.

### Q: What if v2 doesn't work?
**A**: v1 continues as-is. We'll have learned valuable lessons.

### Q: Can I contribute?
**A**: If you have psychometric expertise, yes! Otherwise, contribute to v1.

### Q: Is this privacy compliant?
**A**: That's a primary focus. Differential privacy, opt-in, regular audits.

### Q: Why not use existing adaptive testing software?
**A**: Most are proprietary, cloud-based, and expensive. We need open-source, privacy-preserving, offline-capable.

---

## Conclusion

The **practice_test_generation_v2** branch has been successfully created with comprehensive research planning documentation. This branch represents a major research initiative that will:

1. **Extend v1** with advanced psychometric features
2. **Validate** through rigorous research (n > 1000)
3. **Preserve Privacy** with differential privacy and opt-in
4. **Maintain Ethics** through IRB oversight and fairness audits
5. **Deliver Value** if validated, while v1 remains stable

### Key Takeaways

✅ **Planning Complete** - 60+ pages of documentation  
✅ **Branch Created** - Isolated from production (main)  
✅ **Timeline Set** - 12+ months with 8 phases  
✅ **Budget Known** - ~$180k with detailed breakdown  
✅ **Team Defined** - 3-5 people with specific roles  
✅ **Success Criteria** - Clear validation requirements  
✅ **Risks Identified** - Mitigation strategies planned  

### Status

**Branch**: `practice_test_generation_v2`  
**Commits**: 2 (documentation only)  
**Code Changes**: None yet (planning phase)  
**Next Phase**: Team formation & IRB submission  
**Merge Blockers**: IRB, validation, privacy audit, user testing  

---

**⚠️ This is a RESEARCH branch. Do not merge to main without validation. ⚠️**

---

**Created**: December 16, 2025  
**Last Updated**: December 16, 2025  
**Status**: 🔬 Planning Phase Complete
