local M = {}

function M.use_flat_config(root_dir)
  if
    vim.fn.filereadable(root_dir .. '/eslint.config.js') == 1
    or vim.fn.filereadable(root_dir .. '/eslint.config.mjs') == 1
    or vim.fn.filereadable(root_dir .. '/eslint.config.cjs') == 1
    or vim.fn.filereadable(root_dir .. '/eslint.config.ts') == 1
    or vim.fn.filereadable(root_dir .. '/eslint.config.mts') == 1
    or vim.fn.filereadable(root_dir .. '/eslint.config.cts') == 1
  then
    return true
  end
  return false
end

function M.resolve_node_path()
  -- Check if the OS is Windows
  if vim.loop.os_uname().sysname ~= "Windows_NT" then
    print("This function is only for Windows systems.")
    return nil
  end

  -- Run `where.exe node` to get the Node.js path
  local result = vim.fn.system('where.exe node')

  -- Trim trailing newline character(s)
  result = result:gsub("\r\n$", ""):gsub("\n$", "")

  -- Handle errors if the command fails
  if vim.v.shell_error ~= 0 then
    print("Error: Could not find Node.js path.")
    return nil
  end

  return result
end

function M.setup_autocmd()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'typescript', 'typescriptreact' },
    callback = function(args)
      local root_dir = vim.fs.root(args.buf, { 'package.json' });
      vim.lsp.start({
        name = 'eslint',
        cmd = { 'node', '--inspect-brk',vim.fn.stdpath('config') .. '/lua/nvim-eslint/vscode-eslint/server/out/eslintServer.js', '--stdio' },
        root_dir = root_dir,
        settings = {
          validate = 'on',
          packageManager = 'pnpm',
          useESLintClass = false,
          experimental = {
            useFlatConfig = false,
          },
          useFlatConfig = M.use_flat_config(root_dir),
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
          nodePath = M.resolve_node_path(),
          -- use the workspace folder location or the file location (if no workspace folder is open) as the working directory
          workingDirectory = { directory = root_dir },
          workspaceFolder = {
            uri = root_dir,
            name = vim.fn.fnamemodify(root_dir, ':t'),
          },
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
