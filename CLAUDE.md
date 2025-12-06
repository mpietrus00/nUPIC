# CLAUDE.md - Repository Instructions

## PDF Handling

When working with PDF files in this repository:

1. **Extract PDF to text first** - Use `pdftotext` via Bash to convert PDF to `.txt`
   ```bash
   pdftotext input.pdf output.txt
   ```

2. **Process the text file** - Work with the extracted `.txt` file, not the PDF directly

3. **Keep extracted files** - Store `.txt` files alongside their source PDFs for future reference
