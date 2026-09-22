return {
  {
    -- Seamless navigation between Neovim windows and tmux panes
    -- (tmux side: vim-tmux-navigator loaded via tmux plugins.conf)
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<C-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<C-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<C-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
    },
    lazy = false,
  },
  {
    -- Lets tmux-resurrect save/restore Neovim sessions
    -- ("set -g @resurrect-strategy-nvim 'session'" in tmux.conf)
    "tpope/vim-obsession",
    event = "VeryLazy",
  },
}
