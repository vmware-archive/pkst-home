require 'rubygems'
require 'interactive_editor'
require 'irb/completion'
IRB.conf[:PROMPT_MODE] = :SIMPLE
IRB.conf[:EVAL_HISTORY] = 100000
IRB.conf[:SAVE_HISTORY] = 100000
IRB.conf[:HISTORY_FILE] = File::expand_path("~/.irb_history")