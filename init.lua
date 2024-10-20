local M = {}
function M.setup_autocmd()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'typescript', 'typescriptreact' },
    callback = function(args)
      vim.lsp.start({
        name = 'eslint',
        cmd = { 'node', '--inspect-brk',vim.fn.stdpath('config') .. '/lua/nvim-eslint/vscode-eslint/server/out/eslintServer.js', '--stdio' },
        root_dir = vim.fs.root(args.buf, { 'package.json' }),
        workspace_folders = nil,
        settings = {
          validate = 'on',
          packageManager = nil,
          useESLintClass = false,
          experimental = {
            useFlatConfig = false,
          },
          codeActionOnSave = {
            enable = false,
            mode = 'all',
          },
          format = true,
          quiet = false,
          onIgnoredFiles = 'off',
          rulesCustomizations = {},
          run = 'onType',
          problems = {
            shortenToSingleLine = false,
          },
          -- nodePath configures the directory in which the eslint server should start its node_modules resolution.
            -- This path is relative to the workspace folder (root dir) of the server instance.
            nodePath = '',
          -- use the workspace folder location or the file location (if no workspace folder is open) as the working directory
          workingDirectory = { mode = 'location' },
          codeAction = {
            disableRuleComment = {
              enable = true,
              location = 'separateLine',
            },
            showDocumentation = {
              enable = true,
            },
          },
        },
      })
    end
  })
end

function M.setup()
  M.setup_autocmd()
end
return M
