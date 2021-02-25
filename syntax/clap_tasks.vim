
syn match ClapTaskName     '^\S\+'
syn match ClapTaskScope    '^\S\+\s*\zs<.*>\ze\s*:'
syn match ClapTaskCommand  '^.*:\zs.*'

hi default link ClapTaskName          Keyword
hi default link ClapTaskScope         ErrorMsg
hi default link ClapTaskCommand       Comment


