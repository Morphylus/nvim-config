return {
    {
        'mason-org/mason.nvim',
        lazy = false,
        opts = {}
    },
    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        config = function()
            local cmp = require('cmp')

            cmp.setup({
                sources = { {
                    name = 'nvim_lsp'
                } },
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-d>'] = cmp.mapping.scroll_docs(4),

                    -- Use enter to confirm completion
                    ['<CR>'] = cmp.mapping.confirm({
                        select = false
                    }),

                    -- Navigate completions with <C-j> and <C-k>
                    ["<C-j>"] = cmp.mapping.select_next_item({
                        behavior = cmp.SelectBehavior.Insert
                    }),
                    ["<C-k>"] = cmp.mapping.select_prev_item({
                        behavior = cmp.SelectBehavior.Insert
                    }),

                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.confirm({ select = true })
                        elseif vim.snippet.active() then
                            vim.snippet.jump(1)
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                }),
                snippet = {
                    expand = function(args)
                        vim.snippet.expand(args.body)
                    end
                }
            })
        end
    },
    -- LSP
    -- Neovim handles LSP natively (vim.lsp.config / vim.lsp.enable). nvim-lspconfig
    -- only ships the default server configs (cmd, filetypes, root markers) and
    -- mason-lspconfig enables every server installed through :Mason.
    {
        'neovim/nvim-lspconfig',
        cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = { 'hrsh7th/cmp-nvim-lsp', 'mason-org/mason.nvim', 'mason-org/mason-lspconfig.nvim' },
        config = function()
            -- Defaults for every language server
            vim.lsp.config('*', {
                capabilities = require('cmp_nvim_lsp').default_capabilities(),
            })

            vim.lsp.config('eslint', {
                settings = {
                    eslint = {
                        enable = true,
                        packageManager = "yarn",
                        configFiles = ".eslint.config.mjs",
                        validate = "on"
                    }
                }
            })

            vim.lsp.config('lua_ls', {
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { 'vim' },
                        },
                    },
                },
            })

            -- Swift only, C/C++ is handled by clangd
            vim.lsp.config('sourcekit', {
                filetypes = { 'swift' },
                cmd = {
                    "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
                },
            })

            -- Servers that are not installed through mason
            vim.lsp.enable({ 'gdscript', 'sourcekit' })

            -- Enables every server installed through mason
            require('mason-lspconfig').setup({
                ensure_installed = { "eslint", "clangd" },
            })

            -- Define the autoformat function locally
            local buffer_autoformat = function(bufnr)
                local group = vim.api.nvim_create_augroup('lsp_autoformat', {
                    clear = false
                })
                vim.api.nvim_clear_autocmds({
                    group = group,
                    buf = bufnr
                })

                vim.api.nvim_create_autocmd('BufWritePre', {
                    buf = bufnr,
                    group = group,
                    desc = 'LSP format on save',
                    callback = function()
                        -- note: do not enable async formatting
                        vim.lsp.buf.format({
                            async = false,
                            timeout_ms = 10000
                        })
                    end
                })
            end

            -- LspAttach is where you enable features that only work
            -- if there is a language server active in the file
            vim.api.nvim_create_autocmd('LspAttach', {
                desc = 'LSP actions',
                callback = function(event)
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client == nil then
                        return
                    end

                    -- Autoformat on save
                    if client:supports_method('textDocument/formatting') then
                        buffer_autoformat(event.buf)
                    end

                    local map = function(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, { buf = event.buf, silent = true, desc = desc })
                    end

                    map('n', 'gd', vim.lsp.buf.definition, "Go to definition")
                    -- Go to definition in split window: Split window, move to left and open definition
                    map('n', 'gD', '<cmd>vsplit | wincmd L | lua vim.lsp.buf.declaration()<cr>',
                        "Go to definition in split window")
                    map('n', 'gi', vim.lsp.buf.implementation, "Go to implementation")
                    map('n', 'go', vim.lsp.buf.type_definition, "Go to type definition")
                    map('n', 'gr', vim.lsp.buf.references, "Show references")
                    map('n', 'gs', vim.lsp.buf.signature_help, "Show signature help")
                    map('n', 'gR', vim.lsp.buf.rename, "Rename")
                    map({ 'n', 'x' }, 'f', function() vim.lsp.buf.format({ async = true }) end, "Format selection")
                    map('n', '<F4>', vim.lsp.buf.code_action, "Code action")
                end
            })

            -- Prevent autoformatting of comments in C and Cpp code
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "c", "cpp" },
                callback = function()
                    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
                end,
            })
        end
    } }
