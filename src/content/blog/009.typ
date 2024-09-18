#let date = datetime(
  year: 2024,
  month: 6,
  day: 23,
)

#metadata((
  "title": "clash 配置chatgpt的rule",
  "author": "dashuai009",
  description: "这是一种将C++更加现代的代码组织方式。 模块是一组源代码文件，独立于导入它们的翻译单元进行编译。",
  pubDate: date.display(),
  subtitle: [clash rule],
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf

#date.display();

#outline()

= 问题

openai.com检查的内容很多，clash的rule模式一般过不去。我这里必须切到golbal模式才可以访问。找了半天，clash可以配置Parser，在机场提供的配置文件外，添加规则配置。自定义规则可以单独设置，我想要gpt相关的访问全部走美国节点。

= 使用Parser

Parser是针对机场给的配置文件，新增一些规则，这样机场节点少了也可能还可以复用。
```
clash > Profiles > 右键配置 > Parsers > Edit parsers
```
向打开的文件添加以下内容。

```text
parsers: # array
  - url: YOUR_URL
    yaml:
      prepend-proxy-groups:
        - name: 🚀 OpenAI
          type: select
          proxies:
            - 美国 A
            - 美国 B
            - 美国 C
            - 美国 D [0.5x]
            - 美国 E [0.5x]
      prepend-rules:
        - DOMAIN,browser-intake-datadoghq.com,🚀 OpenAI
        - DOMAIN,static.cloudflareinsights.com,🚀 OpenAI
        - DOMAIN-SUFFIX,ai.com,🚀 OpenAI
        - DOMAIN-SUFFIX,algolia.net,🚀 OpenAI
        - DOMAIN-SUFFIX,api.statsig.com,🚀 OpenAI
        - DOMAIN-SUFFIX,auth0.com,🚀 OpenAI
        - DOMAIN-SUFFIX,chatgpt.com,🚀 OpenAI
        - DOMAIN-SUFFIX,chatgpt.livekit.cloud,🚀 OpenAI
        - DOMAIN-SUFFIX,client-api.arkoselabs.com,🚀 OpenAI
        - DOMAIN-SUFFIX,events.statsigapi.net,🚀 OpenAI
        - DOMAIN-SUFFIX,featuregates.org,🚀 OpenAI
        - DOMAIN-SUFFIX,host.livekit.cloud,🚀 OpenAI
        - DOMAIN-SUFFIX,identrust.com,🚀 OpenAI
        - DOMAIN-SUFFIX,intercom.io,🚀 OpenAI
        - DOMAIN-SUFFIX,intercomcdn.com,🚀 OpenAI
        - DOMAIN-SUFFIX,launchdarkly.com,🚀 OpenAI
        - DOMAIN-SUFFIX,oaistatic.com,🚀 OpenAI
        - DOMAIN-SUFFIX,oaiusercontent.com,🚀 OpenAI
        - DOMAIN-SUFFIX,observeit.net,🚀 OpenAI
        - DOMAIN-SUFFIX,segment.io,🚀 OpenAI
        - DOMAIN-SUFFIX,sentry.io,🚀 OpenAI
        - DOMAIN-SUFFIX,stripe.com,🚀 OpenAI
        - DOMAIN-SUFFIX,turn.livekit.cloud,🚀 OpenAI
        - DOMAIN-SUFFIX,openai.com,🚀 OpenAI
```

注意
1. url后的YOUR_URL就是机场提供的配置链接。
2. prepend-proxy-groups是将之后定义的组加到已有groxy-groups的前面。新建一个“🚀 OpenAI”的组，之后在Proxies里就能看到新建了这个组。复制想要的proxies的名字列表。
3. prepend-rules的配置来自#link("https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Clash/OpenAI/OpenAI.yaml")[这里]
4. 注意：我的配置文件跟上边不太同，去掉了最后三个个IP的配置和DOMAIN-KEYWORD的配置，报了个错忘了是啥了；加上了`- DOMAIN-SUFFIX,openai.com,🚀 OpenAI`这一行，让`openai.com`域名也走美国节点。
5. 可能还需要重启一下clash

= Parser配置说明

#table(
  columns: (1fr, auto),
  inset: 10pt,
  align: horizon,
  table.header("键", "操作"),
  "append-rules", "数组合并至原配置 rules 数组后",
  "prepend-rules", " 数组合并至原配置 rules 数组前",
  "append-proxies", " 数组合并至原配置 proxies 数组后",
  "prepend-proxies", " 数组合并至原配置 proxies 数组前",
  "append-proxy-groups", " 数组合并至原配置 proxy-groups 数组后",
  "prepend-proxy-groups", " 数组合并至原配置 proxy-groups 数组前",
  "mix-proxy-providers ", "对象合并至原配置 proxy-providers 中",
  "mix-rule-providers", " 对象合并至原配置 rule-providers 中",
  "mix-object", " 对象合并至原配置最外层中",
  "commands ", "在上面操作完成后执行简单命令操作配置文件",
)
