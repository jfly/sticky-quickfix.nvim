> [!WARNING]
> This plugin is archived:
> - I upstreamed the core logic to Vim in <https://github.com/vim/vim/pull/15841>
> - That landed in Neovim in <https://github.com/neovim/neovim/pull/30820>
> - I've made a followup change to Neovim to make even easier to use here <https://github.com/neovim/neovim/pull/30868>

# sticky-quickfix

If you update a quickfix list, Neovim loses your location in the list.

This is annoying if you're *fix*ing items in the quickfix list and want the
quickfix list to refresh as you. You'll lose your spot!

For example, here's what happens without this plugin:

![demonstration of vim quickfix list losing the quickfix location](doc/before.svg)

In case that's hard to follow, here's what happening above:

1. `vi hgttg.py`: Open a Python file with a bunch of warning diagnostics.
2. `:lua vim.diagnostic.setqflist()`: Populate the quickfix list with those diagnostics.
3. `jj...<CR>`: Select and "open" the Nth diagnostic.
4. Fix the diagnostic by removing the unnecessary `f`-string.
5. `:lua vim.diagnostic.setqflist()`: Repopulate the quickfix list. Note that
   the quickfix list now has the first entry selected, even though we were
   quite a ways down the list.

And here's the exact same sequence of events, but with this plugin enabled.
Note where how we end in a different (more sane) place in the quickfix list:

![demonstration of vim quickfix list preserving the quickfix location](doc/after.svg)

## How does this work?

This plugin monkeypatches `vim.fn.setqflist` to look like this:

1. Get current quickfix location index.
2. Run original `vim.fn.setqflist`.
3. Given the current line/column, search for the nearest entry in the
   quickfix left. Update the quickfix index to that index. If the current
   file doesn't show up in the quickfix list, fall back to the quickfix
   index from step 1).

As we're monkeypatching Lua code, this isn't going to work if some Vimscript
code does a `:call setqflist(...)`, or if some internal Neovim code invokes the
underlying C functionality. Please let me know if there's a better way to
accomplish this!

## Prior art

- This is the only previous discussion I've found about this issue:
  <https://github.com/onsails/diaglist.nvim/issues/6>.
- I haven't been able to find other plugins that implement this. Please let me
  know if I missed one!
- For LSP diagontics, some people use
  [trouble.nvim](https://github.com/folke/trouble.nvim), which does not have this
  issue.
- It sounds like Neovim will accept this patch if it lands in Vim:
  - Discussion with Neovim: <https://github.com/neovim/neovim/issues/30724#issuecomment-2402040885>
  - My attempt to add this to Vim: <https://github.com/vim/vim/pull/15841>

# Development

- `nix fmt`: Format all code.
- `nix run .#neovim-demo`: Try out a Neovim with this plugin configured.
- `nix run .#play-demo -- --no-plugin`: Watch what happens without this plugin.
  - `nix build .#record-demo-before && cp result/demo.svg doc/before.svg`: Record that demo and update the docs.
- `nix run .#play-demo -- --plugin`: Watch the same thing, but this time with the plugin.
  - `nix build .#record-demo-after && cp result/demo.svg doc/after.svg`: Record that demo and update the docs.
