# Include hook code here

RewriteRails

ActiveSupport::Dependencies.unhook!

RewriteRails.hook_the_hook!

ActiveSupport::Dependencies.hook!