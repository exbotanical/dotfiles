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

const config = Object.fromEntries(
  registers.map(r => [
    `Asm${r.charAt(0).toUpperCase()}${r.slice(1)}Register`,
    {
      prefix: r,
      body: `%${r}`,
    },
  ]),
)

// eslint-disable-next-line no-console -- CLI generator; stdout is the snippet JSON it produces
console.log(JSON.stringify(config))
