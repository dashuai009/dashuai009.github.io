#let date = datetime(
  year: 2022,
  month: 5,
  day: 14,
)
#metadata((
  "title": "angular服务端渲染",
  "author": "dashuai009",
  description: "",
  pubDate: date.display(),
  subtitle: [angular,angular_universal,ssr],
))<frontmatter>

#import "../../__template/style.typ": conf
#show: conf



#date.display();
#outline()


== Angular 统一平台简介

[Angular Universal：Angular 统一平台简介](https://angular.cn/guide/universal)

> 本指南讲的是Angular Universal（统一平台），一项在服务端运行 Angular 应用的技术。
>
> 标准的 Angular 应用会运行在浏览器中，它会在 DOM 中渲染页面，以响应用户的操作。 而Angular Universal 会在服务端运行，生成一些静态的应用页面，稍后再通过客户端进行启动。 这
意味着该应用的渲染通常会更快，让用户可以在应用变得完全可交互之前，先查看应用的布局。

== 参考文档

[Angular Universal：Angular 统一平台简介](https://angular.cn/guide/universal)

[Rendering on web](https://developers.google.com/web/updates/2019/02/rendering-on-the-web)

[Angular Universal: a Complete Practical Guide](https://blog.angular-university.io/angular-universal/)

== 示例代码

[Angular Universal: a Complete Practical Guide](https://github.com/angular-university/angular-universal-course)

[个人代码](https://github.com/dashuai009/angularUniversal)

== 为何需要服务端渲染？

有三个主要的理由来为你的应用创建一个 Universal 版本。

- 通过搜索引擎优化(SEO)来帮助网络爬虫。
- 提升在手机和低功耗设备上的性能
- 迅速显示出第一个支持首次内容绘制(FCP)的页面

== 案例

以我的博客渲染过程为例。

这里给出一个比较大的例子，为了方便展示setTitle等部分。

如果单纯在服务端向`<div></div>`插入一段`html`代码也可以。

== 如何使用

要创建服务端应用模块 app.server.module.ts，请运行以下 CLI 命令。

```text
ng add @nguniversal/express-engine
```

该命令会创建如下文件夹结构。

```text

src/
index.html                 app web page
main.ts                    bootstrapper for client app
main.server.ts             * bootstrapper for server app
style.css                  styles for the app
app/ ...                   application code
app.server.module.ts     * server-side application module
server.ts                    * express web server
tsconfig.json                TypeScript base configuration
tsconfig.app.json            TypeScript browser application configuration
tsconfig.server.json         TypeScript server application configuration
tsconfig.spec.json           TypeScript tests configuration

```

![被修改的文件](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/5/2021-05-15%2018-17-06%20%E7%9A%84%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE.png)

在我的package.json中有如下定义

```json

{
  "script":{
    "dev:ssr": "ng run blog:serve-ssr",
    "serve:ssr": "node dist/blog/server/main.js",
    "build:ssr": "ng build --prod && ng run blog:server:production",
    "prerender": "ng run blog:prerender"
  }
}

```

之后运行`npm run dev:ssr`(与运行`ng run blog:serve-ssr`等价)，可以在本地测试。

生产环境下可以用`npm run build:ssr`编译项目。和 `npm run srve:ssr` 运行项目。

== 目标

打开一个article的时候

- 直接从服务器段拿到已经把md渲染为html
- 前端无需再去请求md文档

== 重复获取数据

=== 了解状态转移API

有了App Shell，现在让我们讨论另一个常见的服务器端渲染优化：客户端启动时服务器到客户端的状态转移。

首先让我们谈谈State Transfer API解决的问题。当我们的Angular Universal应用程序启动时，页面的很大一部分已经被渲染，并且从一开始就对用户可见。

但是请记住，此服务器端呈现的应用程序将从服务器中提取普通的客户端应用程序，然后该应用程序将接管页面。

然后，此Angular客户端应用程序将启动，并且它将做的第一件事是什么？它会联系服务器并再次获取所有数据！

客户端应用程序甚至会在加载数据时打开加载指示器。对于用户来说这很奇怪，因为来自服务器的页面中已经有数据，那么为什么应用程序又要加载它呢？

然后，客户端将重新呈现所有数据，并将其再次传递给页面，并将其显示给用户。

所有这一切都有一个问题：服务器刚刚检索了数据并呈现了数据，那么为什么还要在客户端上再次重复相同的过程呢？这是多余的，它查询服务器两次，并且不能提供良好的用户体验，这是我们 首先使用Universal的主要原因。

=== Transfer API如何工作？

为了解决重复数据获取的问题，我们需要的是通用应用程序将其数据存储在页面上某个位置，然后使其可用于客户端应用程序的方式，而无需再次调用服务器。

这正是State Transfer API允许我们执行的操作！State Transfer API为我们提供了一个存储容器，用于在服务器和客户端应用程序之间轻松地传输数据，从而避免了客户端应用程序必须与服务 器联系以获取数据的需求。

=== 添加transferStateModule

[Here](https://angular.cn/api/platform-browser/TransferState)

angular提供了一种在服务器和浏览器之间，进行数据传输的一个接口。数据是附加在html后边中的一个script的标签中。

> 我踩的坑：这个数据自动进行json的解码转码。不要再对数据进行JSON.parse和JSON.stringify，无法处理html的标签，"<"

分别在app.server.module.ts和app.module.ts中，分别添加`ServerTransferStateModule`和`BrowserTransferStateModule`。

![server](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/5/2021-05-15%2020-56-04%20%E7%9A%84%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE.png)

![browser](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/5/2021-05-15%2020-56-20%20%E7%9A%84%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE.png)

=== 编写resovler

在app.module.ts中声明（provider）resoler.ts模块。

之后，就可以在该文件中利用TransferState模块处理数据。

== 服务端是否渲染

进行一些细粒度的控制，可以使用自定义结构指令来实现：appShellRender和appShellNoRender。


#table(
  columns: (1fr, auto),
  inset: 10pt,
  align: horizon,
  "appShellRender", "服务端渲染",
  "appShellNoRender", "服务端不渲染",
)

请注意，appShellRender和appShellNoRender对客户端没有任何影响！在浏览器中，每次我们浏览单个页面应用程序时，整个模板都会呈现出来。

[代码示例](https://github.com/angular-university/angular-universal-course/tree/2-express-engine-finished/src/app/directives)

== 编写服务端不渲染的组件

服务端渲染的用法简单，且就这样了。
如果想写服务端不加载的组件，又不想在组件里适配，有一种hack的写法，这里简单记录一下。

```html
<my-comp *ngif = "show | sync"></my-comp>
```

show可以是上层组件中的`Observable<boolean>`，在服务端传递`of(false)`即可。这样服务端不会渲染`my-comp`组件。