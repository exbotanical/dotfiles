#!/usr/bin/env node

const registers = [
  'rax',
  'rbx',
  'rcx',
  'rsp',
  'rbp',
  'rdi',
  'rsi',
  'rdx',
  'eax',
  'ebx',
  'ecx',
  'esp',
  'ebp',
  'edi',
  'esi',
  'edx',
  'ax',
  'bx',
  'cx',
  'sp',
  'bp',
  'di',
  'si',
  'dx',
  'ah',
  'al',
  'bh',
  'bl',
  'ch',
  'cl',
  'spl',
  'bpl',
  'dil',
  'sil',
  'dh',
  'dl',
]

const config = registers.reduce(
  (acc, r) => ({
    ...acc,
    [`Asm${r.charAt(0).toUpperCase()}${r.slice(1)}Register`]: {
      prefix: r,
      body: `%${r}`,
    },
  }),
  {},
)

console.log(JSON.stringify(config))
