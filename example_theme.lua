-- styla.nvim theme file

return {
  colors = {
    black = "#000000",
    blue = "#0000ff",
    cyan = "#00ffff",
    dim_blue = "#000055",
    dim_cyan = "#005555",
    dim_green = "#005500",
    dim_magenta = "#550055",
    dim_red = "#550000",
    dim_yellow = "#555500",
    gray_1 = "#dddddd",
    gray_2 = "#aaaaaa",
    gray_3 = "#555555",
    gray_4 = "#222222",
    green = "#00ff00",
    magenta = "#ff00ff",
    red = "#ff0000",
    white = "#ffffff",
    yellow = "#ffff00",
  },
  resolve = {
    default = {
      comment = {
        "@comment",
        "Comment",
      },
      token = {
        "Normal",
      },
    },
    lua = {
      ["function"] = {
        "@lsp.type.function.lua",
        "@lsp.type.function",
        "@variable.lua",
        "@variable",
        "@function.call.lua",
        "@function.call",
        "@function.builtin.lua",
        "@function.builtin",
        "Normal",
      },
    },
    python = {
      comment = {
        "@comment",
        "Comment",
        "@comment.python",
        "@spell.python",
        "@spell",
        "Normal",
      },
      ["keyword.function"] = {
        "@keyword.function.python",
        "@keyword.function",
        "Normal",
      },
      variable = {
        "@variable.python",
        "@variable",
        "Normal",
        "@function.python",
        "@function",
      },
    },
    typescript = {
      ["keyword.import"] = {
        "@keyword.import.typescript",
        "@keyword.import",
        "Normal",
      },
      ["keyword.type"] = {
        "@keyword.type",
        "Normal",
        "@keyword.type.typescript",
      },
      variable = {
        "Normal",
        "@variable.member.typescript",
        "@variable.member",
        "@lsp.type.variable",
        "@lsp.type.variable.typescript",
      },
    },
  },
  specs = {
    ["@comment"] = {
      fg = {
        color = "dim_green",
        h = 0,
        l = 0,
        s = 0,
      },
      style = {},
    },
    ["@comment.python"] = {
      fg = {
        color = "cyan",
        h = -9,
        l = -10,
        s = 3,
      },
      style = {
        "italic",
      },
    },
    ["@function"] = {
      style = {},
    },
    ["@function.builtin"] = {
      style = {},
    },
    ["@function.builtin.lua"] = {
      style = {},
    },
    ["@function.call"] = {
      style = {},
    },
    ["@function.call.lua"] = {
      style = {},
    },
    ["@function.python"] = {
      fg = {
        color = "red",
        h = -44,
        l = 0,
        s = -52,
      },
      style = {},
    },
    ["@keyword.function"] = {
      style = {},
    },
    ["@keyword.function.python"] = {
      fg = {
        color = "black",
        h = 0,
        l = 38,
        s = 0,
      },
      style = {
        "bold",
      },
    },
    ["@keyword.import.typescript"] = {
      fg = {
        color = "gray_2",
        h = -16,
        l = -22,
        s = -37,
      },
      style = {},
    },
    ["@keyword.type.typescript"] = {
      fg = {
        color = "magenta",
        h = -24,
        l = 21,
        s = -16,
      },
      style = {
        "italic",
      },
    },
    ["@lsp.type.function"] = {
      style = {},
    },
    ["@lsp.type.function.lua"] = {
      style = {},
    },
    ["@lsp.type.variable"] = {
      fg = {
        color = "green",
        h = -37,
        l = 0,
        s = -32,
      },
      style = {},
    },
    ["@lsp.type.variable.typescript"] = {
      fg = {
        color = "gray_2",
        h = 0,
        l = 5,
        s = 8,
      },
      style = {},
    },
    ["@spell"] = {
      style = {},
    },
    ["@spell.python"] = {
      style = {},
    },
    ["@variable"] = {
      style = {},
    },
    ["@variable.lua"] = {
      fg = {
        color = "yellow",
        h = -10,
        l = 0,
        s = 0,
      },
      style = {},
    },
    ["@variable.member"] = {
      style = {},
    },
    ["@variable.member.typescript"] = {
      fg = {
        color = "gray_1",
        h = 0,
        l = 0,
        s = 0,
      },
      style = {},
    },
    ["@variable.python"] = {
      fg = {
        color = "green",
        h = -45,
        l = 18,
        s = 0,
      },
      style = {},
    },
    Comment = {
      fg = {
        color = "dim_magenta",
        h = 0,
        l = 0,
        s = 0,
      },
      style = {
        "italic",
      },
    },
    Normal = {
      bg = {
        color = "black",
        h = 0,
        l = 0,
        s = 0,
      },
      fg = {
        color = "white",
        h = 0,
        l = 0,
        s = 0,
      },
      style = {},
    },
  },
}

