local M = {}

--- Writes to error buffer.
---@param ... string Will be concatenated before being written
local function err_message(...)
  vim.notify(table.concat(vim.iter({ ... }):flatten():totable()), vim.log.levels.ERROR)
  api.nvim_command('redraw')
end

function M.resolve_git_dir(bufnr)
  local markers = { '.git' }
  local git_dir = vim.fs.root(bufnr, markers);
  return git_dir
end

function M.resolve_package_json_dir(bufnr)
  local markers = { 'package.json' }
  local package_json_dir = vim.fs.root(bufnr, markers);
  return package_json_dir
end

function M.make_settings(git_dir, package_json_dir)
  return {
    validate = 'on',
    -- packageManager = 'pnpm',
    useESLintClass = true,
    useFlatConfig = M.use_flat_config(package_json_dir),
    experimental = {
      useFlatConfig = false,
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
    codeActionOnSave = {
      mode = 'all',
    },
    format = false,
    quiet = false,
    onIgnoredFiles = 'off',
    options = {},
    rulesCustomizations = {},
    run = 'onType',
    problems = {
      shortenToSingleLine = false,
    },
    -- nodePath configures the directory in which the eslint server should start its node_modules resolution.
    -- This path is relative to the workspace folder (root dir) of the server instance.
    nodePath = M.resolve_node_path(),
    -- use the workspace folder location or the file location (if no workspace folder is open) as the working directory
    workingDirectory = { directory = package_json_dir },
    workspaceFolder = {
      uri = git_dir,
      name = vim.fn.fnamemodify(git_dir, ':t'),
    },

  }
end

function M.make_client_capabilities()
  local default_capabilities = vim.lsp.protocol.make_client_capabilities()
  default_capabilities.workspace.didChangeConfiguration.dynamicRegistration = true
  return default_capabilities
end

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
  local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
  local command = is_windows and 'where.exe node' or 'which node'

  -- Run the appropriate command to get the Node.js path
  local result = vim.fn.system(command)

  -- Trim trailing newline character(s)
  result = result:gsub("\r\n$", ""):gsub("\n$", "")

  -- Handle errors if the command fails
  if vim.v.shell_error ~= 0 then
    print("Error: Could not find Node.js path. ESlint server will use default path.")
    return nil
  end

  return result
end

function M.create_cmd()
  local debug = true -- for debugging language server
  if debug then
    return { 'node', '--inspect-brk', vim.fn.stdpath('config') ..
    '/lua/nvim-eslint/vscode-eslint/server/out/eslintServer.js', '--stdio' }
  end
  return { 'node', vim.fn.stdpath('config') .. '/lua/nvim-eslint/vscode-eslint/server/out/eslintServer.js', '--stdio' }
end

function M.setup_autocmd()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'typescript', 'typescriptreact' },
    callback = function(args)
      local git_dir = M.resolve_git_dir(args.buf)
      local package_json_dir = M.resolve_package_json_dir(args.buf)
      vim.lsp.start({
        name = 'eslint',
        cmd = M.create_cmd(),
        root_dir = git_dir,
        settings = M.make_settings(git_dir, package_json_dir),
        capabilities = M.make_client_capabilities(),
        handlers = {
          ["workspace/configuration"] = function (_, result, ctx)
            local function lookup_section(table, section)
              local keys = vim.split(section, '.', { plain = true }) --- @type string[]
              return vim.tbl_get(table, unpack(keys))
            end

            local client_id = ctx.client_id
            local client = vim.lsp.get_client_by_id(client_id)
            if not client then
              err_message(
                'LSP[',
                client_id,
                '] client has shut down after sending a workspace/configuration request'
              )
              return
            end
            if not result.items then
              return {}
            end
            
            print('result', vim.inspect(result))

            print('ctx', vim.inspect(ctx))

            --- Insert custom logic to update client settings
            local bufnr = vim.uri_to_bufnr(result.items[1].scopeUri)
            local new_git_dir = M.resolve_git_dir(bufnr)
            local new_package_json_dir = M.resolve_package_json_dir(bufnr)
            local new_settings = M.make_settings(new_git_dir, new_package_json_dir)
            client.settings = new_settings
            print 'client.settings updated'
            --- end custom logic
            
            print('client.settings', vim.inspect(client.settings))

            local response = {}
            for _, item in ipairs(result.items) do
              if item.section then
                local value = lookup_section(client.settings, item.section)
                -- For empty sections with no explicit '' key, return settings as is
                if value == nil and item.section == '' then
                  value = client.settings
                end
                if value == nil then
                  value = vim.NIL
                end
                table.insert(response, value)
              end
            end
            return response
          end
        }
      })
    end
  })
end

function M.setup()
  M.setup_autocmd()
end

return M
