################################################################################
#
# FINAL-PROJECT
#
################################################################################

#TODO: Fill up the contents below in order to reference your assignment 7 git contents
#Reference: https://stackoverflow.com/questions/24750215/getting-the-last-commit-hash-from-a-remote-repo-without-cloning/24750310
#			https://stackoverflow.com/questions/468370/a-regex-to-match-a-sha1
FINAL_PROJECT_VERSION = $(shell git ls-remote \
	https://github.com/cu-ecen-aeld/final-project-rajatchaple.git HEAD | \
	grep -o -E  "[0-9a-f]{40}")

# Note: Be sure to reference the *ssh* repository URL here (not https) to work properly
# with ssh keys and the automated build/test system.
# Your site should start with git@github.com:
FINAL_PROJECT_SITE = 'git@github.com:cu-ecen-aeld/final-project-rajatchaple.git'
FINAL_PROJECT_SITE_METHOD = git
FINAL_PROJECT_GIT_SUBMODULES = YES

FINAL_PROJECT_MODULE_SUBDIRS = code/adv-driver-1

FINAL_PROJECT_MODULE_MAKE_OPTS = KVERSION=$(LINUX_VERSION_PROBED)

define FINAL_PROJECT_INSTALL_TARGET_CMDS

endef


$(eval $(kernel-module))
$(eval $(generic-package))