#let date = datetime(
  year: 2026,
  month: 1,
  day: 20,
)
#metadata((
  title: "https:// to ssh",
  subtitle: [git],
  author: "dashuai009",
  description: "git config",
  pubDate: date.display(),
))<frontmatter>


== backup

Replace `git://` with `https://`
Rewrite any `git://` urls to be `https://` but, it won't touch sshurls (`git@github.com:`)

```
git config --global url."https://github".insteadOf git://github
```

or replace with ssh

Use ssh instead of `https://`

```
git config --global url."git@github.com:".insteadOf "https://github.com/"
```
