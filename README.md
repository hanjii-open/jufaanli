# Usage

```
ruby src/main.rb [all|import|scrape|export|reset]
```

## import

将外部文书导入内部数据库。执行前需要将 zip 文件放在 `tmp/zip` 目录中。

## scrape

从数据库中的文书提取罪名信息。

## export

将罪名信息和文书导出成表格。导出结果在 `tmp` 目录中，文件名为 `[代号]_[罪名].csv`。

## all

依次执行上述3个步骤。

## reset

重置数据库。

# Installation

1. Ruby 3.1+
1. ActiveRecord 7.0+

---

by linjinbo
