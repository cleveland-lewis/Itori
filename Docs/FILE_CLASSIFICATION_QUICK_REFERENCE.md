# File Classification + CSV Auto-Scheduling — Quick Reference

**Feature:** Automatically create assignments from CSV files  
**Status:** ✅ Production Ready  
**Branch:** `feature/file-classification-parsing`

---

## 🚀 Quick Start (3 Steps)

### 1. Prepare Your CSV

Create a CSV file with these columns (any order):

**Required:**
- `title` or `name` or `assignment` — Assignment name

**Optional:**
- `type` or `category` — Type (homework, quiz, exam, project, reading, review)
- `due` or `duedate` or `date` — Due date
- `points` or `weight` — Point value (not yet used)

**Example:**
```csv
title,type,due,points
Homework 1,homework,2026-01-15,10
Quiz 2,quiz,2026-01-20,25
Midterm Exam,exam,2026-02-15,100
```

### 2. Import to Course

1. Open **Courses** page
2. Select a course
3. Click **"Add Files"**
4. Select your CSV file
5. File appears in "Course Files" list

### 3. Classify as Syllabus

1. Click category dropdown on file card (far right)
2. Select **"Syllabus"** or **"Assignment List"**
3. Wait 1-2 seconds
4. Watch status: Queued → Parsing → Parsed ✅

**Result:** Assignments automatically appear in Planner!

---

## 📊 Supported Date Formats

The parser recognizes 9 date formats:

| Format | Example |
|--------|---------|
| ISO | `2026-01-15` |
| ISO with slashes | `2026/01/15` |
| US format | `01/15/2026` |
| US with dashes | `01-15-2026` |
| European | `15/01/2026` |
| European with dashes | `15-01-2026` |
| Short month | `Jan 15, 2026` |
| Long month | `January 15, 2026` |
| Day first | `15 Jan 2026` |

**Tip:** Use ISO format (`YYYY-MM-DD`) for best compatibility.

---

## 🏷️ Type Mapping

CSV `type` column → Task type in app:

| CSV Value | Maps To | Time Estimate |
|-----------|---------|---------------|
| `homework` | Homework | 90 min |
| `quiz` | Quiz | 60 min |
| `exam`, `test`, `midterm`, `final` | Exam | 180 min |
| `project`, `paper`, `essay`, `lab` | Project | 300 min |
| `reading` | Reading | 45 min |
| `review` | Review | 60 min |
| (anything else) | Homework | 90 min |

**Note:** Time estimates are defaults. You can edit them in the Planner.

---

## 🔄 Re-Importing (No Duplicates)

**Safe to re-import!** The system uses deduplication:

**Unique Key:** `courseId + title + dueDate + type`

If you import the same CSV twice:
- Existing assignments are skipped
- Only new/changed items are added
- Logs show: ⏭️ "Skip duplicate"

**To Force Re-Parse:**
1. Delete old assignments manually
2. Re-import CSV
3. New assignments created

---

## 🎯 File Categories

Choose the right category for auto-parsing:

| Category | Auto-Parse? | Use Case |
|----------|-------------|----------|
| **Syllabus** | ✅ Yes | Course schedule CSVs or PDFs |
| **Assignment List** | ✅ Yes | Standalone CSV of tasks |
| **Rubric** | ✅ Yes | Grading criteria (future) |
| **Practice Test** | ✅ Yes | Sample questions (future) |
| **Test** | ✅ Yes | Past exams (future) |
| **Class** | ✅ Yes | Lecture notes (future) |
| **Notes** | ❌ No | Personal notes |
| **Other** | ❌ No | Misc files |
| **Uncategorized** | ❌ No | Default |

**Tip:** For CSVs, use "Syllabus" or "Assignment List"

---

## ⚠️ Troubleshooting

### ❌ Status shows "Failed"

**What to do:**
1. Click category dropdown
2. Click **"View Error"**
3. Read error message

**Common Errors:**

| Error | Cause | Fix |
|-------|-------|-----|
| `Missing required column: title/name/assignment` | No title column | Add `title` column to CSV |
| `Unable to read file (invalid encoding)` | Not UTF-8 | Save CSV as UTF-8 |
| `File is empty` | Empty CSV | Add data rows |
| `File not found or inaccessible` | Permission issue | Re-import file |

### 📝 No Assignments Created

**Check:**
1. CSV has `title` column (required)
2. File category is "Syllabus" or "Assignment List"
3. Status is "Parsed" (not "Failed")
4. Assignments page refreshed

**Still not working?**
- Check console logs (Developer Mode)
- Look for: 📊 "CSVParse: N assignments"
- If N = 0, check CSV format

### 🔁 Parsing Never Completes

**Status stuck on "Queued" or "Parsing":**
1. Wait 5-10 seconds (processing)
2. Check if file is very large (1000+ rows)
3. Check console for errors
4. Try re-categorizing file

---

## 📖 Examples

### Example 1: Simple Homework CSV

```csv
title,due
Homework 1,2026-01-15
Homework 2,2026-01-22
Homework 3,2026-01-29
```

**Result:** 3 homework tasks, 90 min each

---

### Example 2: Mixed Types

```csv
name,type,date
Weekly Quiz 1,quiz,01/15/2026
Reading Ch 1-3,reading,01/17/2026
Lab Report 1,project,01/22/2026
Midterm Exam,exam,02/05/2026
```

**Result:** 4 tasks with different types and estimates

---

### Example 3: Flexible Columns

```csv
assignment,category,duedate,weight
Problem Set 1,homework,January 15, 2026,10
Exam 1,exam,February 12, 2026,100
```

**Result:** Works! Column names are flexible.

---

## 🔧 Advanced Tips

### Bulk Import Multiple Courses

1. Create separate CSVs per course
2. Name files: `COURSE-syllabus.csv` (e.g., `BIO101-syllabus.csv`)
3. Import each to correct course
4. Classify all as "Syllabus"
5. All assignments auto-created

### Semester Schedule Template

```csv
title,type,due,points
Week 1 - Quiz,quiz,2026-01-15,10
Week 2 - Quiz,quiz,2026-01-22,10
Week 3 - Quiz,quiz,2026-01-29,10
Week 4 - Midterm,exam,2026-02-05,50
Week 5 - Quiz,quiz,2026-02-12,10
Week 6 - Quiz,quiz,2026-02-19,10
Week 7 - Quiz,quiz,2026-02-26,10
Week 8 - Final,exam,2026-03-05,100
```

Save as template, duplicate for each course, adjust dates.

### Export from Canvas/Blackboard

Most LMS export assignment lists as CSV:
1. Go to course gradebook
2. Export → CSV
3. Keep `title` and `due` columns
4. Delete extra columns if needed
5. Import to Itori

---

## 🎓 Best Practices

**DO:**
- ✅ Use ISO dates (`YYYY-MM-DD`)
- ✅ Keep CSVs simple (title + due minimum)
- ✅ Test with small CSV first (3-5 rows)
- ✅ Review assignments in Planner after import
- ✅ Use consistent type values

**DON'T:**
- ❌ Mix date formats in same CSV
- ❌ Use dates before 2024 or after 2030
- ❌ Include special characters in titles (stick to letters/numbers)
- ❌ Leave cells blank (use "TBD" if needed)

---

## 📈 What Gets Imported

**From CSV:**
- ✅ Title → Assignment title
- ✅ Due date → Assignment due date
- ✅ Type → Task type (homework/quiz/etc)
- ⚠️ Points → Stored but not used yet

**Auto-Generated:**
- Time estimate (based on type)
- Task ID (unique)
- Course link (from import context)

**Not Imported:**
- Notes/descriptions (future)
- Attachments (future)
- Grading rubrics (future)

---

## 🐛 Known Limitations

1. **No PDF/DOCX parsing yet** — Only CSV works
2. **No progress bar** — Large files show no progress
3. **No bulk confirmation** — 100+ items auto-created
4. **No assignment editing during import** — Edit after
5. **No custom time estimates** — Uses defaults

**Coming in Phase 3:**
- PDF syllabus parsing
- Progress tracking
- Batch import review UI
- Custom time estimates per row

---

## 💡 Feature Roadmap

### Phase 1 ✅ (Complete)
- File classification dropdown
- Parse status tracking
- 9 file categories
- Real-time UI updates

### Phase 2 ✅ (Complete)
- CSV parsing engine
- Auto-scheduling
- Deduplication
- Type mapping
- Date parsing (9 formats)

### Phase 3 📋 (Planned)
- PDF text extraction
- DOCX text extraction
- Assignment pattern detection
- Progress tracking
- Batch import confirmation

### Phase 4 🔮 (Future)
- Rubric parsing
- Topic extraction for practice tests
- AI-powered syllabus analysis
- Conflict resolution UI

---

## 📞 Support

**Issue:** CSV not parsing correctly  
**Action:** Export detailed error report (Developer Settings)

**Issue:** Duplicates created  
**Action:** Check unique key in logs (courseId + title + date + type)

**Issue:** Wrong time estimates  
**Action:** Edit manually in Planner (custom estimates coming)

---

**Last Updated:** January 3, 2026  
**Version:** 2.0 (Phase 2 Complete)  
**Tested On:** macOS Sequoia, iOS 17+
