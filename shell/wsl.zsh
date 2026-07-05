# ============================================================================
#  WSL — overlay specifico WSL (caricato DOPO linux.zsh)
# ============================================================================
# WSL è Linux a tutti gli effetti ($OSTYPE = linux-gnu): la config di base
# arriva da common.zsh + linux.zsh. Qui va solo ciò che esiste unicamente
# dentro WSL (interop con Windows).

# ----------------------------------------------------------------------------
#  Clipboard — pbcopy/pbpaste come su macOS (memoria muscolare)
# ----------------------------------------------------------------------------
alias pbcopy="clip.exe"
alias pbpaste="powershell.exe -command 'Get-Clipboard' | sed 's/\r//'"
