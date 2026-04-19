# pdf-reader.nvim

Small local Neovim plugin for opening PDFs as extracted text via `pdftotext`.

## Features

- `:OpenPdf path/to/file.pdf`
- Transparent `*.pdf` opening through `BufReadCmd`
- Optional page markers based on PDF page breaks
- Read-only scratch buffer output

## Requirements

- `pdftotext` available in `$PATH`

## Notes

- This extracts text; it does not render the PDF visually.
- Scanned PDFs without OCR may produce little or no text.
