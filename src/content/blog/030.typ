#let date = datetime(
  year: 2022,
  month: 8,
  day: 28,
)

#metadata((
  title: "为存有Box<dyn T>的结构体实现Clone",
  subtitle: [rust],
  author: "dashuai009",
  description: "为存有Box<dyn T>的结构体实现Clone how to clone a struct storing a boxed trait object",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


== 问题描述：
<问题描述>
无法为以下结构体实现Clone：

```rust

pub trait GetName {
    fn get_name(&self) -> String;
}

#[device(Clone)]
struct Node{
    name: String,
    children: Vec<Box<dyn GetName>>
}
```

== 参考链接
<参考链接>
#link("https://stackoverflow.com/questions/30353462/how-to-clone-a-struct-storing-a-boxed-trait-object")[stackoverflow how-to-clone-a-struct-storing-a-boxed-trait-object]

== 具体实现
<具体实现>
```rust
// 先为GetName继承一个能clone的trait
pub trait GetName: NodeClone{
    fn get_name(&self) -> String;
}

//自定义一个clone,里面套默认clone
pub trait NodeClone {
    fn clone_box(&self) -> Box<dyn GetName>;
}

//自定义clone接口，where限制这个NodeClone只是用在GetName上，
//如果不借助这个NodeClone,直接pub tarit GetName:Clone{}是不行的
//没法放在Box<>里
impl<T> NodeClone for T
where
    T: 'static + GetName + Clone,
{
    fn clone_box(&self) -> Box<dyn GetName> {
        Box::new(self.clone())
    }
}


//为Box<dyn T>实现Clone,调用dyn GetName的自定义Clone
impl Clone for Box<dyn GetName> {
    fn clone(&self) -> Box<dyn GetName> {
        self.clone_box()
    }
}

#[derive(Clone)]
pub struct Node {
    name: String,
    children: Vec<Box<dyn GetName>>//子元素只要能GetName就可以
}

impl GetName for Node{
    fn get_name(&self) -> String{
        return self.name.clone();
    }
}

impl Node{
    //将子元素的name拼起来打印
    pub fn print_children(&self)->String{
        let s = self.children.iter()
        .map(|n|n.get_name())
        .collect::<Vec<_>>()
        .join(",");
        format!("[{}]",s)
    }
}

fn main() {

    let a1= Box::new(Node{
        name: "a1111".to_string(),
        children:vec![]
    });
    let a2= Box::new(Node{
        name: "a2".to_string(),
        children:vec![]
    });

    let b = Node{
        name: "bbb".to_string(),
        //测试一下，to_vec()会调用每个元素的Clone
        //a1、a2具体类型是Node,具有GetName、Clone接口，
        children:[a1 as Box<dyn GetName>,a2 as Box<dyn GetName>].to_vec()
    };

    println!("b={}",b.print_children());


}
```
