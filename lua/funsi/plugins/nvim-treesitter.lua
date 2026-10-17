return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").install({
            "lua", "gdscript", "godot_resource", "gdshader", "vim", "javascript", "html", "rust", "typescript", "glsl",
            "wgsl", "bash", "c", "cpp", "cmake", "markdown", "markdown_inline", "python", "swift",
        })

        -- Highlighting and indentation for every filetype that has a parser
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(event)
                if not pcall(vim.treesitter.start, event.buf) then
                    return
                end
                local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
                if lang and vim.treesitter.query.get(lang, "indents") then
                    vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })
    end
}
