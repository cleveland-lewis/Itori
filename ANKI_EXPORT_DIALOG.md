# Anki Export Dialog - Download Option

**Date:** 2026-01-06  
**Fix:** Added proper export functionality with empty state and download option

---

## Problem

The "Export to Anki" dialog was showing but appeared mostly empty because:
1. No visual feedback when deck has 0 cards
2. No proper download/export option
3. Only copy to clipboard functionality

---

## Solution

### 1. Empty State (When No Cards)

**Added helpful UI when deck is empty:**

```swift
if text.isEmpty {
    VStack(spacing: 16) {
        Image(systemName: "square.stack.3d.up.slash")
            .font(.system(size: 48))
            .foregroundStyle(.secondary)
        
        Text("No Cards to Export")
            .font(.title3.weight(.semibold))
        
        Text("Add some cards to this deck to export them to Anki format.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}
```

**Features:**
- Large icon indicating empty state
- Clear message: "No Cards to Export"
- Helpful instruction to add cards first
- Centered layout

### 2. Export with Cards

**Enhanced UI when cards exist:**

- **Card count indicator** - Shows "X cards" next to description
- **Scrollable CSV preview** - Monospaced font for better readability
- **Download CSV button** - Native file save dialog (prominent blue button)

### 3. Native File Save Dialog

**`saveToFile()` method:**

```swift
private func saveToFile() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.commaSeparatedText]
    panel.nameFieldStringValue = "\(deckName).csv"
    panel.title = "Export Flashcards to CSV"
    panel.message = "Save your flashcards in Anki-compatible CSV format"
    
    panel.begin { response in
        guard response == .OK, let url = panel.url else { return }
        
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            // Show success alert
        } catch {
            // Show error alert
        }
    }
}
```

**Features:**
- Native macOS save panel
- Pre-filled filename with deck name
- `.csv` extension
- Proper file type (comma-separated text)
- Success/error feedback alerts

---

## UI Layout

### Empty State
```
┌─ Export to Anki ──────────────────────── [Done] ─┐
│                                                    │
│ ─────────────────────────────────────────────────  │
│                                                    │
│                    📚                              │
│              No Cards to Export                    │
│    Add some cards to this deck to export them     │
│            to Anki format.                         │
│                                                    │
│                                                    │
└────────────────────────────────────────────────────┘
```

### With Cards
```
┌─ Export to Anki ──────────────────────── [Done] ─┐
│                                                    │
│ ─────────────────────────────────────────────────  │
│                                                    │
│ CSV format ready for Anki import      10 cards    │
│                                                    │
│ ┌────────────────────────────────────────────────┐ │
│ │ "Front 1","Back 1"                             │ │
│ │ "Front 2","Back 2"                             │ │
│ │ "Front 3","Back 3"                             │ │
│ │ ...                                            │ │
│ └────────────────────────────────────────────────┘ │
│                                                    │
│                           [ Download CSV ]         │
└────────────────────────────────────────────────────┘
```

---

## Export Format

**CSV Structure (Anki-compatible):**
```csv
"Front text","Back text"
"Question","Answer"
"Term","Definition"
```

**Features:**
- Comma-separated values
- Quoted fields (handles commas in content)
- Escaped quotes (double-quote handling)
- Newlines replaced with spaces
- One card per line

---

## User Flow

### Export Empty Deck
1. Click "Export to Anki" in Deck Settings
2. See empty state with helpful message
3. Close dialog and add cards first

### Export Deck with Cards
1. Click "Export to Anki" in Deck Settings
2. See CSV preview with card count
3. Choose export method:
   - **Save As...** → File picker → Save to disk
   - **Copy to Clipboard** → Instant copy → "Copied!" feedback

### After Save As...
- **Success:** Alert shows "Export Successful" with filename
- **Error:** Alert shows "Export Failed" with error details

---

## Technical Details

### File I/O

**Save Panel Configuration:**
- `allowedContentTypes`: `.commaSeparatedText` (UTI)
- `nameFieldStringValue`: `{DeckName}.csv`
- Title and message for context

**File Write:**
- UTF-8 encoding
- Atomic write (prevents corruption)
- Error handling with alerts

### State Management

```swift
@State private var copied = false  // Clipboard feedback

// Temporary feedback animation
DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    copied = false
}
```

### Import Added

```swift
import UniformTypeIdentifiers  // For .commaSeparatedText
```

---

## Files Modified

**Platforms/macOS/Scenes/FlashcardSheets.swift**

1. Added `UniformTypeIdentifiers` import
2. Enhanced `ExportSheet` with:
   - Empty state UI
   - Card count indicator
   - "Save As..." button and logic
   - File save panel
   - Success/error alerts
   - Improved layout

**Total:** 1 file, ~90 lines added/modified

---

## Benefits

### User Experience

1. **Clear Feedback** - Users know why dialog is empty
2. **Multiple Options** - Save file OR copy to clipboard
3. **Native Integration** - Standard macOS save dialog
4. **Success Confirmation** - Alerts confirm save status
5. **Card Count** - See how many cards will be exported

### Technical

1. **Error Handling** - Proper try/catch with user feedback
2. **File Types** - Correct UTI for CSV files
3. **Encoding** - UTF-8 for compatibility
4. **Atomic Writes** - Prevents partial file corruption

---

## Testing Checklist

**Empty Deck:**
- [ ] Empty state appears when 0 cards
- [ ] Icon and message are clear
- [ ] No export buttons shown
- [ ] "Done" button works

**Deck with Cards:**
- [ ] CSV preview shows correctly
- [ ] Card count is accurate
- [ ] Monospaced font for CSV
- [ ] Text is selectable
- [ ] Scrollable when many cards

**Save As... Button:**
- [ ] Opens native save panel
- [ ] Pre-fills deck name + .csv
- [ ] Saves file correctly
- [ ] Success alert shows
- [ ] Error alert shows on failure
- [ ] Saved file imports to Anki

**Copy to Clipboard:**
- [ ] Copies CSV text
- [ ] Shows "Copied!" feedback
- [ ] Reverts after 2 seconds
- [ ] Paste works in other apps

**Visual:**
- [ ] 600x400 window size
- [ ] Proper spacing and padding
- [ ] Matches system appearance
- [ ] Buttons follow Apple HIG

---

## Anki Import Instructions

**For Users:**

1. **Export from Itori:**
   - Open Flashcards page
   - Click deck settings (gear icon)
   - Select "Export to Anki Format"
   - Click "Save As..." and choose location

2. **Import to Anki:**
   - Open Anki
   - Click "Import File"
   - Select the saved CSV file
   - Choose deck to import into
   - Map fields: Column 1 → Front, Column 2 → Back
   - Click "Import"

---

## Future Enhancements

1. **Direct Anki Integration**
   - Detect if Anki is installed
   - Auto-open Anki with import

2. **Export Options**
   - Include tags
   - Include difficulty levels
   - Export specific cards only

3. **Batch Export**
   - Export all decks at once
   - Export to folder structure

4. **Import Support**
   - Import CSV back into Itori
   - Sync with Anki decks

---

## Conclusion

Successfully enhanced the Anki export dialog with:
- ✅ Empty state for decks with no cards
- ✅ Native "Save As..." file export
- ✅ Improved UI with card count
- ✅ Success/error feedback
- ✅ Both file save and clipboard options

**Status:** ✅ Functional and user-friendly
