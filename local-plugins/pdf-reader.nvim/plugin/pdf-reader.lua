if vim.g.loaded_pdf_reader_nvim == 1 then
	return
end

vim.g.loaded_pdf_reader_nvim = 1

require("pdf-reader").setup()
