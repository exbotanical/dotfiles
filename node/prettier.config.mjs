import exbotanical from '@exbotanical/prettier-config'

export default exbotanical({
  plugins: {
    nginx: true,
    properties: true,
    shell: true,
    solidity: true,
    sql: true,
    toml: true,
    xml: true,
  },
})
