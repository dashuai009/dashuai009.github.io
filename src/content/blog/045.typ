
#let date = datetime(
  year: 2023,
  month: 10,
  day: 11,
)
#metadata((
  title: "gltf-transform使用记录",
  subtitle: [gltf],
  author: "dashuai009",
  description: "",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf



```text
 -> ~ gltf-transform --help
node:internal/modules/cjs/loader:1075
  const err = new Error(message);
              ^

Error: Cannot find module 'call-bind'
Require stack:
- /home/dashuai/.nvm/versions/node/v18.15.0/lib/node_modules/@gltf-transform/cli/node_modules/@ljharb/through/index.js
    at Module._resolveFilename (node:internal/modules/cjs/loader:1075:15)
    at Module._load (node:internal/modules/cjs/loader:920:27)
    at Module.require (node:internal/modules/cjs/loader:1141:19)
    at require (node:internal/modules/cjs/helpers:110:18)
    at Object.<anonymous> (/home/dashuai/.nvm/versions/node/v18.15.0/lib/node_modules/@gltf-transform/cli/node_modules/@ljharb/through/index.js:4:16)
    at Module._compile (node:internal/modules/cjs/loader:1254:14)
    at Module._extensions..js (node:internal/modules/cjs/loader:1308:10)
    at Module.load (node:internal/modules/cjs/loader:1117:32)
    at Module._load (node:internal/modules/cjs/loader:958:12)
    at ModuleWrap.<anonymous> (node:internal/modules/esm/translators:169:29) {
  code: 'MODULE_NOT_FOUND',
  requireStack: [
    '/home/dashuai/.nvm/versions/node/v18.15.0/lib/node_modules/@gltf-transform/cli/node_modules/@ljharb/through/index.js'
  ]
}

Node.js v18.15.0
```

以上错误是因为call-bind没有找到，只需要`npm install call-bind`即可