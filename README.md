# Usage

```
ruby src/main.rb [all|import|scrape|export|reset|reset!] [crimeN...]
```

## import

将外部文书导入内部数据库。执行前需要将 zip 文件放在 `tmp/zip` 目录中。

## scrape

从数据库中的文书提取罪名信息。

## export

将罪名信息和文书（概要）导出成表格。导出结果在 `tmp` 目录中，文件名为 `[代号]_[罪名].csv`。

## all

依次执行上述3个步骤。

## reset

只重置 crime 数据库。

## export!

在 `export` 的基础上，额外导出文书全文。

## reset!

重置全部数据库。

## crimeN

可以指定目标罪名，可用名包括 `crime1...crime6` 。

# Installation

1. Ruby 3.1+
1. ActiveRecord 7.0+

---

by linjinbo
