" pablo_red: pablo base + warmer literal values only.
set background=dark

" Reset to default groups, then load pablo as the base.
source $VIMRUNTIME/colors/vim.lua
runtime colors/pablo.vim

let g:colors_name = 'pablo_red'

" Global palette remap on top of Pablo.
lua << EOF
local map = {
  -- green -> #42be65
  [0x00ff00] = 0x42be65,
  [0x00c000] = 0x42be65,
  [0x00cd00] = 0x42be65,
  [0x5f875f] = 0x42be65,

  -- blue -> #33b1ff
  [0x0000ff] = 0x33b1ff,
  [0x0000ee] = 0x33b1ff,
  [0x00008b] = 0x33b1ff,
  [0x5c5cff] = 0x33b1ff,
  [0x80a0ff] = 0x33b1ff,
  [0x5f87af] = 0x33b1ff,

  -- magenta/pink -> #be95ff
  [0xff00ff] = 0xbe95ff,
  [0xcd00cd] = 0xbe95ff,
  [0xaf5faf] = 0xbe95ff,
  [0xff77dd] = 0xbe95ff,
}

for _, group in ipairs(vim.fn.getcompletion("", "highlight")) do
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if ok and hl then
    local changed = false
    for _, key in ipairs({ "fg", "bg", "sp" }) do
      local color = hl[key]
      local mapped = type(color) == "number" and map[color] or nil
      if mapped then
        hl[key] = mapped
        changed = true
      end
    end
    if changed then
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end
EOF

" Literal values use the remapped magenta target.
hi Constant  guifg=#be95ff ctermfg=147 cterm=NONE
hi String    guifg=#be95ff ctermfg=147 cterm=NONE
hi Character guifg=#be95ff ctermfg=147 cterm=NONE
hi Number    guifg=#be95ff ctermfg=147 cterm=NONE
hi Boolean   guifg=#be95ff ctermfg=147 cterm=NONE
hi Float     guifg=#be95ff ctermfg=147 cterm=NONE
