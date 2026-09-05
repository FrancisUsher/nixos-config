{ pkgs, lib, ... }:
let
  languages = {
    lua = {
      server = "lua_ls";
      serverSettings.Lua.completion.callSnippet = "Replace";
      grammars = [ "lua" "luadoc" ];
    };
    python = {
      server = "basedpyright";
      grammars = [ "python" ];
    };
    css = {
      server = "cssls";
      grammars = [ "css" ];
    };
    toml = {
      server = "taplo";
      grammars = [ "toml" ];
    };
    typescript = {
      server = "ts_ls";
      grammars = [ "typescript" "tsx" "javascript" ];
    };
  };

  # Grammars with no matching LSP server - Neovim-internal/structural
  # languages (diff, query, vimdoc) or ones no server is configured for.
  extraGrammars = [ "bash" "c" "diff" "html" "markdown" "markdown_inline" "query" "vim" "vimdoc" ];

  treesitterGrammars = extraGrammars ++ builtins.concatLists (map (lang: lang.grammars) (builtins.attrValues languages));

  nvim-tcss = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-tcss";
    version = "2024-01-24";
    src = pkgs.fetchFromGitHub {
      owner = "cachebag";
      repo = "nvim-tcss";
      rev = "bf9001416158f32fe7e92c42de94de3595aa13e5";
      hash = "sha256-QHY+UzJrFir/gtj7KDzxvSgFfckG+xwGtd6YyDk81lc=";
    };
  };
in
{
  # obsidian.nvim's workspace below expects ~/notes to already exist; it
  # errors out on startup rather than creating it itself.
  home.file."notes/.keep".text = "";

  stylix.targets.nixvim.enable = true;

  programs.nixvim = {
    enable = true;
    # Reuse home-manager's already-built pkgs instead of nixvim importing
    # its own separate instance from nixpkgs.source.
    nixpkgs.useGlobalPackages = true;
    viAlias = true;
    vimAlias = true;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      have_nerd_font = true;
    };

    opts = {
      number = true;
      relativenumber = true;
      mouse = "a";
      showmode = false;
      breakindent = true;
      undofile = true;
      ignorecase = true;
      smartcase = true;
      signcolumn = "yes";
      updatetime = 250;
      timeoutlen = 300;
      splitright = true;
      splitbelow = true;
      list = true;
      listchars = {
        tab = "» ";
        lead = "·";
        trail = "·";
        nbsp = "␣";
      };
      inccommand = "split";
      cursorline = true;
      scrolloff = 10;
      confirm = true;
      smartindent = true;
      expandtab = true;
      tabstop = 2;
      shiftwidth = 2;
      conceallevel = 2;
    };

    clipboard.register = "unnamedplus";

    # Colorscheme comes from Stylix (modules/stylix.nix's
    # stylix.targets.nixvim, mini.base16) instead of being set here.

    keymaps = [
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR>";
      }
      {
        mode = "n";
        key = "<leader>q";
        action.__raw = "vim.diagnostic.setloclist";
        options.desc = "Open diagnostic [Q]uickfix list";
      }
      {
        mode = "t";
        key = "<Esc><Esc>";
        action = "<C-\\><C-n>";
        options.desc = "Exit terminal mode";
      }
      {
        mode = "n";
        key = "<left>";
        action = "<cmd>echo \"Use h to move!!\"<CR>";
      }
      {
        mode = "n";
        key = "<right>";
        action = "<cmd>echo \"Use l to move!!\"<CR>";
      }
      {
        mode = "n";
        key = "<up>";
        action = "<cmd>echo \"Use k to move!!\"<CR>";
      }
      {
        mode = "n";
        key = "<down>";
        action = "<cmd>echo \"Use j to move!!\"<CR>";
      }
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w><C-h>";
        options.desc = "Move focus to the left window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w><C-l>";
        options.desc = "Move focus to the right window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w><C-j>";
        options.desc = "Move focus to the lower window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w><C-k>";
        options.desc = "Move focus to the upper window";
      }
    ];

    autoCmd = [
      {
        event = [ "TextYankPost" ];
        desc = "Highlight when yanking (copying) text";
        callback.__raw = "function() vim.hl.on_yank() end";
      }
    ];

    extraPlugins = [ nvim-tcss pkgs.vimPlugins.lazydev-nvim ];
    extraPackages = [ pkgs.python3Packages.autopep8 ];
    extraConfigLua = ''
      -- lazydev.nvim has no nixvim module; configure it directly.
      require('lazydev').setup {
        library = {
          { path = "''${3rd}/luv/library", words = { 'vim%.uv' } },
        },
      }
    '';
    extraConfigLuaPost = ''
      require('mini.statusline').section_location = function()
        return '%2l:%-2v'
      end
    '';

    plugins = {
      gitsigns = {
        enable = true;
        settings.signs = {
          add.text = "+";
          change.text = "~";
          delete.text = "_";
          topdelete.text = "‾";
          changedelete.text = "~";
        };
      };

      which-key = {
        enable = true;
        settings = {
          delay = 0;
          spec = [
            {
              __unkeyed-1 = "<leader>s";
              group = "[S]earch";
            }
            {
              __unkeyed-1 = "<leader>t";
              group = "[T]oggle";
            }
            {
              __unkeyed-1 = "<leader>h";
              group = "Git [H]unk";
              mode = [ "n" "v" ];
            }
          ];
        };
      };

      web-devicons.enable = true;

      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
          ui-select.enable = true;
        };
        keymaps = {
          "<leader>sh" = {
            action = "help_tags";
            options.desc = "[S]earch [H]elp";
          };
          "<leader>sk" = {
            action = "keymaps";
            options.desc = "[S]earch [K]eymaps";
          };
          "<leader>sf" = {
            action = "find_files";
            options.desc = "[S]earch [F]iles";
          };
          "<leader>ss" = {
            action = "builtin";
            options.desc = "[S]earch [S]elect Telescope";
          };
          "<leader>sw" = {
            action = "grep_string";
            options.desc = "[S]earch current [W]ord";
          };
          "<leader>sg" = {
            action = "live_grep";
            options.desc = "[S]earch by [G]rep";
          };
          "<leader>sd" = {
            action = "diagnostics";
            options.desc = "[S]earch [D]iagnostics";
          };
          "<leader>sr" = {
            action = "resume";
            options.desc = "[S]earch [R]esume";
          };
          "<leader>s." = {
            action = "oldfiles";
            options.desc = "[S]earch Recent Files (\".\" for repeat)";
          };
          "<leader><leader>" = {
            action = "buffers";
            options.desc = "[ ] Find existing buffers";
          };
        };
      };

      lsp = {
        enable = true;
        inlayHints = true;

        keymaps = {
          silent = true;
          lspBuf = {
            grn = "rename";
            grD = "declaration";
          };
          extra = [
            {
              key = "gra";
              mode = [ "n" "x" ];
              action.__raw = "vim.lsp.buf.code_action";
              options.desc = "[G]oto Code [A]ction";
            }
            {
              key = "grr";
              action.__raw = "require('telescope.builtin').lsp_references";
              options.desc = "[G]oto [R]eferences";
            }
            {
              key = "gri";
              action.__raw = "require('telescope.builtin').lsp_implementations";
              options.desc = "[G]oto [I]mplementation";
            }
            {
              key = "grd";
              action.__raw = "require('telescope.builtin').lsp_definitions";
              options.desc = "[G]oto [D]efinition";
            }
            {
              key = "grt";
              action.__raw = "require('telescope.builtin').lsp_type_definitions";
              options.desc = "[G]oto [T]ype Definition";
            }
            {
              key = "gO";
              action.__raw = "require('telescope.builtin').lsp_document_symbols";
              options.desc = "Open Document Symbols";
            }
            {
              key = "gW";
              action.__raw = "require('telescope.builtin').lsp_dynamic_workspace_symbols";
              options.desc = "Open Workspace Symbols";
            }
            {
              key = "<leader>th";
              action.__raw = "function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end";
              options.desc = "[T]oggle Inlay [H]ints";
            }
          ];
        };

        onAttach = ''
          local function client_supports_method(client, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

          if client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, bufnr) then
            local highlight_augroup = vim.api.nvim_create_augroup('nixvim-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('nixvim-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'nixvim-lsp-highlight', buffer = event2.buf }
              end,
            })
          end
        '';

        capabilities = ''
          capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)
        '';

        servers = builtins.listToAttrs (map
          (lang: {
            name = lang.server;
            value = { enable = true; }
              // lib.optionalAttrs (lang ? serverSettings) { settings = lang.serverSettings; };
          })
          (builtins.attrValues languages));
      };

      conform-nvim = {
        enable = true;
        settings = {
          notify_on_error = false;
          format_on_save.__raw = ''
            function(bufnr)
              local disable_filetypes = { c = true, cpp = true }
              if disable_filetypes[vim.bo[bufnr].filetype] then
                return nil
              elseif vim.fn.bufname(bufnr):match '.*%.template.css' then
                return nil
              else
                return { timeout_ms = 500, lsp_format = 'fallback' }
              end
            end
          '';
          formatters_by_ft = {
            lua = [ "stylua" ];
            python = [ "autopep8" ];
          };
        };
      };

      blink-cmp = {
        enable = true;
        settings = {
          keymap.preset = "default";
          appearance.nerd_font_variant = "mono";
          completion.documentation = {
            auto_show = false;
            auto_show_delay_ms = 500;
          };
          sources = {
            default = [ "lsp" "path" "snippets" "lazydev" ];
            providers.lazydev = {
              name = "LazyDev";
              module = "lazydev.integrations.blink";
              score_offset = 100;
            };
          };
          snippets.preset = "luasnip";
          fuzzy.implementation = "lua";
          signature.enabled = true;
        };
      };

      luasnip.enable = true;

      fidget.enable = true;

      guess-indent.enable = true;

      colorizer.enable = true;

      todo-comments = {
        enable = true;
        settings.signs = false;
      };

      mini = {
        enable = true;
        modules = {
          ai.n_lines = 500;
          surround = { };
          statusline.use_icons = true;
        };
      };

      treesitter = {
        enable = true;
        nixGrammars = true;
        grammarPackages = map (name: pkgs.vimPlugins.nvim-treesitter.builtGrammars.${name}) treesitterGrammars;
        settings = {
          auto_install = false;
          highlight.enable = true;
          indent.enable = true;
        };
      };

      obsidian = {
        enable = true;
        settings = {
          legacy_commands = false;
          workspaces = [
            {
              name = "notes";
              path = "~/notes";
            }
            {
              name = "nixos-config";
              path = "~/nixos-config/notes";
            }
          ];
          note_id_func.__raw = ''
            function(title)
              if title ~= nil then
                return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
              end
              return tostring(os.time())
            end
          '';
        };
      };
    };
  };
}
