#metadata((
  title: "A angular binding for lexical",
  subtitle: [lexical,angular],
  author: "dashuai009",
  description: "Create a lexical's decorate node using angular custom element. We can build a text editor for angular based on lexical.",
  pubDate: "'Jul 08 2022'",
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


#link("https://angular.io/guide/element")[angular custom element]

== create a normal angular compment
<create-a-normal-angular-compment>
```ts
@Component({
  selector:'lexical-hr',
  template:'<hr/>'
})
export class LexicalHr{
  constructor() {
  }
}
```

== declare golcal interface
<declare-golcal-interface>
```ts
declare global {
  interface HTMLElementTagNameMap {
    'my-dialog': NgElement & WithProperties<{content: string}>;
    'my-other-element': NgElement & WithProperties<{foo: 'bar'}>;
    // 'lexical-image':NgElement & WithProperties<ImageComponent>
    'lexical-hr':NgElement & WithProperties<LexicalHr>
  }
}
```

== Register the custom element with the browser
<register-the-custom-element-with-the-browser>
```ts
export class AppComponent{
  constructor(private injector:Injector) {
    const LexicalHrElement = createCustomElement(LexicalHr, {injector});
    customElements.define('lexical-hr', LexicalHrElement);
  }
}
```

== create lexical’s decorate node
<create-lexicals-decorate-node>
```ts
export const INSERT_HORIZONTAL_RULE_COMMAND: LexicalCommand<void> =
  createCommand();

export class HorizontalRuleNode extends DecoratorNode<NgElement & WithProperties<LexicalHr>> {
  static getType(): string {
    return 'horizontalrule';
  }

  static clone(node: HorizontalRuleNode): HorizontalRuleNode {
    return new HorizontalRuleNode(node.__key);
  }

  static importDOM(): DOMConversionMap | null {
    return {
      hr: (node: Node) => ({
        conversion: convertHorizontalRuleElement,
        priority: 0,
      }),
    };
  }

  override exportDOM(): DOMExportOutput {
    return {element: document.createElement('hr')};
  }

  override createDOM(): HTMLElement {
    const div = document.createElement('div');
    div.style.display = 'contents';
    return div;
  }

  override getTextContent() {
    return '\n';
  }

  override isTopLevel() {
    return true;
  }

  override updateDOM() {
    return false;
  }

  override decorate():any{
    const myHrNode = document.createElement('lexical-hr');
    return myHrNode;
  }
}

function convertHorizontalRuleElement(): DOMConversionOutput {
  return {node: $createHorizontalRuleNode()};
}

export function $createHorizontalRuleNode(): HorizontalRuleNode {
  return new HorizontalRuleNode();
}

export function $isHorizontalRuleNode(node: LexicalNode | null) {
  return node instanceof HorizontalRuleNode;
}
```

The type of `myHrNode` returned by decorate() is
`NgElement & WithProperties<LexicalHr>`, these custom elements will have
a property for each input of the corresponding component.

== register decorator listener
<register-decorator-listener>
```ts
    this.editor.registerDecoratorListener((decorator) => {
      for (let i in decorator) {
        this.editor.getElementByKey(i)?.replaceChildren(decorator[i])
      }
    })
```
