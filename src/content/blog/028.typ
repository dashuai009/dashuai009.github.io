#let date = datetime(
  year: 2022,
  month: 6,
  day: 10,
)
#metadata((
  title: "rust过程宏",
  subtitle: [rust],
  author: "dashuai009",
  description: "使用过程宏自定义一个struct format。",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf



我们有这样一个结构体

```rust
struct TestStruct{
    a:String,
    b:String
}
```

我们希望自定义一个Display。针对`TestStruct{a:String::from("aaa"),b:String::from("bbb")}`形式化输出`a:aaa;b:bbb;`

利用过程宏可以做到这一点，编译时生成`std::fmt::Display`的trait。

#quote[
  刚开始学习过程宏，简单记录自己怎么实现的和一些坑
]

直接上代码

```rust
extern crate proc_macro;
use proc_macro::TokenStream;

use quote::quote;
use syn::{parse_macro_input, Data, DeriveInput, Fields, Ident};

#[proc_macro_derive(format)]
pub fn derive_format(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let struct_name = input.ident;
    let struct_str = Ident::new("struct_str", struct_name.span());
    let expended = if let Data::Struct(r#struct) = input.data {
        if let Fields::Named(ref fields_name) = r#struct.fields {
            let get_selfs: Vec<_> = fields_name
                .named
                .iter()
                .map(|field| {
                    let f = field.ident.as_ref().unwrap();

                    quote! {
                        stringify!(#f),&self.#f
                    }
                })
                .collect();

            let format_string = "{}:{};".repeat(get_selfs.len());
            let format_literal = proc_macro2::Literal::string(format_string.as_str());
            let struct_fields = quote! {
                #(#get_selfs),*
            };

            quote! {
                impl std::fmt::Display for #struct_name{
                    fn fmt(&self,f:&mut std::fmt::Formatter)->std::fmt::Result{
                        write!(f , #format_literal , #struct_fields)
                    }
                }
            }
        } else {
            panic!("sorry, may it's a complicated struct.")
        }
    } else {
        panic!("sorry, Show is not implemented for union or enum type.")
    };
    expended.into()
}
```

难点有两个：

1. `proc_macro2::Literal`

  `format!("{}",str);`语句中格式控制字符串`"{}"`是一个字面量`literal`。

  quote内部使用的第三方库`proc_macro2`，quote语法`#ident`只接受`proc_macro2`的`{TokenStream,Ident,....}`。

  在上边代码中，我们需要将一个String变量转为一个字面量。这个一定要用`proc_macro2::Literal`，用默认库`proc_macro::Literal`，会报错#strong[mismatches types];。#strike[要了命了才看出来这么个事]

2. `#(#get_selfs),*` quote的语法糖

  `write!(f , #format_literal , #struct_fields)` 写出`write!(f , "{:?}" , (#(#get_selfs),*))`这样可以过编译，最后这个参数会生成一个元组，这又没法自定义格式了。 写成`write!(f , #format_literal , #(#get_selfs),*)`又过不了编译。 所以用`let struct_fields = quote!{#(#get_selfs),*}`套了一层。

