module.exports = {
  ...require((process.platform === 'darwin'
    ? '/opt/homebrew/lib/node_modules/'
    : '/usr/lib/node_modules/') + '@magister_zito/prettier-config'),
}
